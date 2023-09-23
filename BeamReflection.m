classdef BeamReflection
    properties
        startingPoint % Initial beam starting point [x, y, z]
        initialpropagateDirection % Propagation direction as a unit vector [dx, dy, dz]
        initialbeamShape % Assumed to be the radius of the beam in X and Y direction [Rx,Ry]
        wavelength % Beam's wavelength
        mirrors % A list to store mirrors
        Positions = {};
        Directions = {};
        Shapes = {};
        ShapeDir = {};
        PlotAx = [];
    end

    methods (Access = public)
        function obj = BeamReflection(startingPoint, propagateDirection, beamShape, wavelength)
            % Constructor to initialize the properties
            obj.startingPoint = startingPoint;
            obj.initialpropagateDirection = propagateDirection/norm(propagateDirection); % Making sure it's a unit vector
            obj.initialbeamShape = beamShape;
            obj.wavelength = wavelength;
            obj.mirrors = {};
        end

        function obj = addMirror(obj, position, direction)
            % Add a mirror to the list
            mirror.position = position;
            mirror.direction = direction/norm(direction); % Making sure it's a unit vector
            obj.mirrors{end+1} = mirror;

            % sort mirrors
            num = length(obj.mirrors);
            for j = 0 : num-1
                for i = 1: num-j-1
                    if obj.mirrors{i}.position>obj.mirrors{i+1}.position
                        temp = obj.mirrors{i};
                        obj.mirrors{i} = obj.mirrors{i+1};
                        obj.mirrors{i+1} = temp;
                    end
                end
            end
        end

        function obj = beamPropagationTraceAndShape(obj)
            % Compute beam propagation after hitting each mirror. This is an oversimplified function and might require more complex calculations for real-life scenarios.

            % For now, just reflecting the beam direction based on the mirror direction
            obj.Positions = {};
            obj.Directions = {};
            obj.ShapeDir = {};
            CurrentDirection = obj.initialpropagateDirection;
            CurrentShape = obj.initialbeamShape;
            CurrentPosition = obj.startingPoint;

            obj.Positions = {CurrentPosition};
            obj.Directions = {CurrentDirection};

            for i = 1:length(obj.mirrors)-1
                mirror = obj.mirrors{i};
                if i >1
                    Lastmirror = obj.mirrors{i-1};
                    CurrentPosition = CurrentDirection*(mirror.position - Lastmirror.position) + CurrentPosition;
                    CurrentShapeDir = obj.ShapeDir{i};
                else

                    CurrentPosition = CurrentDirection*mirror.position + CurrentPosition;
                    CurrentShapeDir = cross(CurrentDirection,mirror.direction);
                    CurrentShapeDir = CurrentShapeDir./norm(CurrentShapeDir);
                    obj.Shapes = CurrentShape;
                    obj.ShapeDir{1} = CurrentShapeDir;
                end

                if abs(dot(CurrentDirection, mirror.direction)) < 1e-12
                    warndlg(['Mirror ',num2str(i),' is parallel to the beam!'])
                elseif abs(dot(CurrentDirection, mirror.direction)-1) < 1e-12
                    warndlg(['Mirror ',num2str(i),' is vertical to the beam!'])
                end

                reflectedDir = CurrentDirection - 2*dot(CurrentDirection, mirror.direction) * mirror.direction;
                CurrentShapeDir = CurrentShapeDir - 2*dot(CurrentShapeDir, mirror.direction) * mirror.direction;
                obj.Directions{end+1} = reflectedDir;
                obj.Positions{end+1}  = CurrentPosition;


                obj.ShapeDir{end+1} = CurrentShapeDir;

                % Updating the direction for the next iteration
                CurrentDirection = reflectedDir;
                %                 CurrentShape = ReflectedShape;
            end

            obj.Positions{end+1}  = CurrentPosition + CurrentDirection*( ...
                obj.mirrors{end}.position-obj.mirrors{end-1}.position);
        end

        function plotBeamAndMirrors(obj)
            % Here, I'm using basic plotting functions. For plotting 3D objects or customized shapes, additional code or external libraries might be required.

            % For now, just plotting beam as lines and mirrors as points in 3D space
            if ~isempty(obj.PlotAx)
                ax = obj.PlotAx;
            else
                ax = gca;
            end
            hold(ax,'on');
            % Convert wavelength to RGB (simplified)
            color = obj.wavelengthToColor(obj.wavelength);

            % Plotting the beam
            currentPoint = obj.startingPoint;
            for i = 1:length(obj.mirrors)
                nextPoint = obj.Positions{i+1};

                plot3(ax,[currentPoint(1) nextPoint(1)], [currentPoint(2) nextPoint(2)], [currentPoint(3) nextPoint(3)], 'Color', color);

                % Plotting the mirrors as points
                plot3(ax,nextPoint(1), nextPoint(2), nextPoint(3), 'o');
                % Moving to the next point
                currentPoint = nextPoint;
            end


            grid(ax,'on');
            axis(ax,'equal') 
            xlabel(ax,'X');
            ylabel(ax,'Y');
            zlabel(ax,'Z');
        end
        function plotBeamShape(obj)
            % Here, I'm using basic plotting functions. For plotting 3D objects or customized shapes, additional code or external libraries might be required.

            % For now, just plotting beam as lines and mirrors as points in 3D space
            if ~isempty(obj.PlotAx)
                ax = obj.PlotAx;
            else
                ax = gca;
            end
            hold(ax,'on');

            % Convert wavelength to RGB (simplified)
            color = obj.wavelengthToColor(obj.wavelength);

            % Plotting the beam

            for i = 1:length(obj.mirrors)
                StartPoint = obj.Positions{i};
                EndPoint = obj.Positions{i+1};
                Shape = obj.Shapes;
                XShapeDirection = obj.ShapeDir{i};
                direction = EndPoint - StartPoint;
                ShapeDirVer = cross(direction,XShapeDirection);
                ShapeDirVer = ShapeDirVer./norm(ShapeDirVer);
                XShapeDirection = XShapeDirection./norm(XShapeDirection);
                StartCircle = [];
                EndCircle = [];
                for theta = 0:0.01:2*pi
                    StartCircle = [StartCircle;
                        StartPoint+Shape(1).* XShapeDirection.*cos(theta)+Shape(2).* ShapeDirVer.*sin(theta)];
                    EndCircle = [EndCircle;
                        EndPoint+Shape(1).* XShapeDirection.*cos(theta)+Shape(2).* ShapeDirVer.*sin(theta)];
                end
                X = [StartCircle(:,1)';EndCircle(:,1)'];
                Y = [StartCircle(:,2)';EndCircle(:,2)'];
                Z = [StartCircle(:,3)';EndCircle(:,3)'];
                surf(ax,X,Y,Z,'FaceColor',color,'EdgeColor','none','FaceAlpha',0.5)
            end

            % Plot the mirror
            for i = 1:length(obj.mirrors)
                mirror = obj.mirrors{i};
                StartPoint = obj.Positions{i+1};
                if dot(mirror.direction,obj.Directions{i}) > 0
                    EndPoint = StartPoint+mirror.direction.*norm(obj.Shapes);
                else
                    EndPoint = StartPoint-mirror.direction.*norm(obj.Shapes);
                end
                Shape =[1 1]*2* norm(obj.Shapes);
                XShapeDirection = cross(mirror.direction,obj.Directions{i});
                XShapeDirection = XShapeDirection./norm(XShapeDirection);

                direction = EndPoint - StartPoint;
                ShapeDirVer = cross(direction,XShapeDirection);
                ShapeDirVer = ShapeDirVer./norm(ShapeDirVer);
                StartCircle = [];
                EndCircle = [];
                for theta = 0:0.01:2*pi
                    StartCircle = [StartCircle;
                        StartPoint+Shape(1).* XShapeDirection.*cos(theta)+Shape(2).* ShapeDirVer.*sin(theta)];
                    EndCircle = [EndCircle;
                        EndPoint+Shape(1).* XShapeDirection.*cos(theta)+Shape(2).* ShapeDirVer.*sin(theta)];
                end
                X = [StartCircle(:,1)';EndCircle(:,1)'];
                Y = [StartCircle(:,2)';EndCircle(:,2)'];
                Z = [StartCircle(:,3)';EndCircle(:,3)'];
                surf(ax,X,Y,Z,'FaceColor',[156 156 156]/255,'EdgeColor','none')
                fill3(ax,X',Y',Z',[156 156 156]/255)
            end


            grid(ax,'on');
            axis(ax,'equal') 
            xlabel(ax,'X');
            ylabel(ax,'Y');
            zlabel(ax,'Z');
        end

        function plotProjectedImg(obj,viewVector)
            if ~isempty(obj.PlotAx)
                ax = obj.PlotAx;
            else
                ax = gca;
            end
            hold(ax,'on');

            ShapeDirection = obj.ShapeDir{end};
            ShapeDirectionVer = cross(obj.Directions{end},ShapeDirection);
            ShapeDirectionVer = ShapeDirectionVer./norm(ShapeDirectionVer);
            viewVector = viewVector./ norm(viewVector);
            ShapeX = obj.Shapes(1).*(ShapeDirection+dot(viewVector,ShapeDirection).*viewVector);
            ShapeY = obj.Shapes(2).*(ShapeDirectionVer+dot(viewVector,ShapeDirectionVer).*viewVector);
            Circle = [];
            for theta = 0:0.01:2*pi
                Circle = [Circle; ShapeX.*cos(theta)+ShapeY.*sin(theta)];

            end
            X = Circle(:,1)';
            Y = Circle(:,2)';
            Z = Circle(:,3)';
            plot3(ax,X,Y,Z)
            view(ax,viewVector)
            grid(ax,'on');
            axis(ax,'equal') 
            xlabel(ax,'X');
            ylabel(ax,'Y');
            zlabel(ax,'Z');
        end
        function color = wavelengthToColor(~, wavelength)
            % A very simplified function to convert wavelength to RGB color.
            % You might need a more detailed conversion depending on the application.
            % Here we assume some arbitrary mapping.
            if wavelength < 500
                color = [0, 0, 1]; % Blue
            elseif wavelength < 600
                color = [0, 1, 0]; % Green
            else
                color = [1, 0, 0]; % Red
            end
        end

        function mirrorInfo = getMirrorInfo(obj, index)
            % Returns position and direction of the specified mirror
            mirror = obj.mirrors{index};
            mirrorInfo.position = mirror.position;
            mirrorInfo.direction = mirror.direction;
        end
        function [file,path] = saveBeam(obj)
            [file,path] = uiputfile('*.mat');
            if isequal(file,0) || isequal(path,0)
               disp('User cancelled saving.')
            else
               save(fullfile(path,file),"obj");
               disp(['File has been saved to ',fullfile(path,file)])
            end
        end


    end
end