function varargout = clickableMultiLegend(varargin)
%clickableMultiLegend extends the clickableLegend by Ameya Deoras to figures with one legend for several subplots
%
%<a href="matlab: docsearch('clickableMultiLegend')">Link to the help page for this function</a>
%
% An example could be a gplotmatrix figure. In this case, by clicking on a
% text label in the legend, we want to turn on and off (hide or show) the
% graphics object (line or patch) associated to that label in all subplots.
%
% The extention to multiple plots is realised by looking for graphics
% objects with the same DisplayName property of the one associated to the
% legend label. Therefore, the function should work also through plots in
% different figures.
%
% See also 
% clickableLegend by Ameya Deoras:
% http://www.mathworks.com/matlabcentral/fx_files/21799/1/clickableLegend.m
%
% Copyright 2008-2011.
% Written by Marco Riani, Domenico Perrotta, Francesca Torti 
%            and Vytis Kopustinskas (2009-2010)
%
%<a href="matlab: docsearch('clickableMultiLegend')">Link to the help page for this function</a>
% Last modified 15-Nov-2011

% Examples

%{
     z = peaks(100);
     plot(z(:,26:5:50))
     grid on;
     clickableMultiLegend({'Line1','Line2','Line3','Line4','Line5'}, 'Location', 'NorthWest');
     axis manual;
     figure;
     z = peaks(100);
     plot(z(:,26:5:50))
     grid on;
     hlegend=clickableMultiLegend({'Line1','Line2','Line3','Line4','Line5'}, 'Location', 'NorthWest');
     axis manual; 
     legend(hlegend,'off');
%}


%% Create legend as if it was called directly
[varargout{1:nargout(@legend)}] = legend(varargin{:});

[~, objhan, plothan] = varargout{1:4}; 
varargout = varargout(1:nargout);

% Set the callbacks
for i = 1:length(plothan)
    set(objhan(i), 'HitTest', 'on', 'ButtonDownFcn',...
        @(varargin)togglevisibility(objhan(i),plothan(i)),...
        'UserData', true);
end

function togglevisibility(hObject, obj)
% hObject is the handle of the text of the legend
if get(hObject, 'UserData') % It is on, turn it off
    set(hObject, 'Color', (get(hObject, 'Color') + 1)/1.5, 'UserData', false);
    set(obj,'HitTest','off','Visible','off','handlevisibility','off');
    
    similar_obj_h = findobj('DisplayName',get(obj,'DisplayName'));
    similar_obj_h(logical(similar_obj_h==obj)) = [];
    %similar_obj_h(find(similar_obj_h==obj)) = []; %slower than line before
    set(similar_obj_h,'HitTest','off','Visible','off','handlevisibility','on');

    % This is to make the patches of a group histogram white
    h = findobj('Type','patch','Tag',get(obj,'DisplayName'));
    if ~isempty(h)
        set(h, 'UserData',get(h,'FaceColor'));
        set(h, 'FaceColor','w', 'EdgeColor','k');
    end
    
else
    set(hObject, 'Color', get(hObject, 'Color')*1.5 - 1, 'UserData', true);
    set(obj, 'HitTest','on','visible','on','handlevisibility','on');
    
    similar_obj_h = findobj('DisplayName',get(obj,'DisplayName'));
    similar_obj_h(logical(similar_obj_h==obj)) = [];
    %similar_obj_h(find(similar_obj_h==obj)) = []; %slower than line before
    set(similar_obj_h,'HitTest','on','Visible','on','handlevisibility','on');

    % This is to re-establish the color of the white patches of a group histogram
    h = findobj('Type','patch','Tag',get(obj,'DisplayName'));
    if ~isempty(h)
        cori = get(h(1),'UserData'); cori = cori{1};
        set(h, 'FaceColor',cori, 'EdgeColor','k');
    end

end
