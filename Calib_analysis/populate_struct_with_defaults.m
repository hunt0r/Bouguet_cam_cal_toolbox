function s = populate_struct_with_defaults(s, default_struct)
% POPULATE_STRUCT_WITH_DEFAULTS
%   POPULATE_STRUCT_WITH_DEFAULTS(s, default_struct) populates the input
%   struct s.  The code scans the fields of default_struct, and if any
%   field in s is missing or empty, the default_struct field-value is
%   used.
%
%   Example:
%     d.a = 3; d.b = 4; d.c = 5;
%     s.a = 10; s.b = [];
%     p = populate_struct_with_defaults(s,d);
%   Results in:
%     p.a = 10; (value from s.a)
%     p.b = 4; (value from d.b)
%     p.c = 5; (value from d.c, note that field 'c' was created)
%
%   HGM, 2014-10-07
%
fld_lst = fields(default_struct);
for fld_ndx = 1:numel(fld_lst)
    fld_name = fld_lst{fld_ndx};
    if ~isfield(s, fld_name)
        s.(fld_name) = [];
    end
    if isempty(s.(fld_name));
        s.(fld_name) = default_struct.(fld_name);
    end
end