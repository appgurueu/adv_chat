local max_linear=10  -- Maximum number of colors for using linear search

-- Finds the closest color using a binary search like thing - point cloud is split into two (ideally equally sized) clouds multiple times which gives a searchable tree

-- Builds a k-d tree for 3d points
function kd_tree_builder(dim)
    return function(points, axis)
        if #points == 1 then
            return points[1]
        end
        axis=(axis or 0)+1
        table.sort(points, function(a,b) return a[axis] > b[axis] end)
        local median=math.floor(#points/2)
        local next_axis=(axis+1)%dim
        return {
            axis=axis,
            pivot=points[median],
            left=build_kd_tree({unpack(points, 1, median)}, next_axis),
            right=build_kd_tree({unpack(points, median+1)}, next_axis)
        }
    end
end

build_kd_tree = kd_tree_builder(3)

distance = function(c1, c2) return math.sqrt(math.pow((c1[1]-c2[1]), 2)+math.pow((c1[2]-c2[2]), 2)+math.pow((c1[3]-c2[3]), 2)) end

-- Returns a function which gives you the closest color, based on k-d trees
function kd_closest_color_finder(colors)
    local tree = build_kd_tree(colors)
    return function(color)
        local min_distance=math.huge
        local closest_color
        f=function(tree)
            local axis=tree.axis
            if #tree > 0 then -- Subtree is leaf
                local distance = distance(tree, color)
                if distance < min_distance then
                    min_distance = distance
                    closest_color = tree
                end
                return
            else
                local new_tree, other_tree = tree.right, tree.left
                if color[axis] < tree.pivot[axis] then
                    new_tree, other_tree = tree.left, tree.right
                end
                f(other_tree)
                if tree.pivot then
                    local dist = math.abs(tree.pivot[axis]-color[axis])
                    if dist <= min_distance then
                        f(new_tree)
                    end
                end
            end
        end
        f(tree)
        return closest_color, min_distance
    end
end

-- returns a function which returns closest color, based on linear search
function linear_closest_color_finder(colors)
    return function(c1)
        local min=math.huge
        local clos
        for _, c2 in pairs(colors) do
            local dis=distance(c1, c2)
            if dis < min then
                min=dis
                clos=c2
            end
        end
        return clos, min
    end
end

-- returns a function for finding the closest color, based on length of colors uses either k-d tree or linear search
function closest_color_finder(colors)
    if #colors <= max_linear then
        return linear_closest_color_finder(colors)
    end
    return kd_closest_color_finder(colors)
end