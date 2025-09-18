"""
    function build(modeltype::Type{MyOneDimensionalElementaryWolframRuleModel}, data::NamedTuple) -> MyOneDimensionalElementarWolframRuleModel

This `build` method constructs an instance of the [`MyOneDimensionalElementaryWolframRuleModel`](@ref) type using the data in a [NamedTuple](https://docs.julialang.org/en/v1/base/base/#Core.NamedTuple).

### Arguments
- `modeltype::Type{MyOneDimensionalElementaryWolframRuleModel}`: The type of model to build, in this case, the [`MyOneDimensionalElementaryWolframRuleModel`](@ref) type.
- `data::NamedTuple`: The data to use to build the model.

The `data::NamedTuple` must contain the following `keys`:
- `index::Int64`: The index of the Wolfram rule
- `colors::Int64`: The number of colors in the rule
- `radius::Int64`: The radius, i.e., the number of cells to consider in the rule

### Return
This function returns a populated instance of the [`MyOneDimensionalElementaryWolframRuleModel`](@ref) type.
"""
function build(modeltype::Type{MyOneDimensionalElementaryWolframRuleModel}, 
    data::NamedTuple)::MyOneDimensionalElementaryWolframRuleModel

    # check: do we have the required keys in the data NamedTuple?
    required_fields = (:index, :colors, :radius);
    for field ∈ required_fields
        if haskey(data, field) == false
            @error "Ooops! Missing required field: $field. Cannot build the model, returning nothing."
            return nothing; # Early return we cannot build the model, so return nothing
        end
    end
    # Checks: we have the required keys in the data NamedTuple, we should check that they are of the correct type
    # ...

    # initialize -
    index = data.index;
    colors = data.colors;
    radius = data.radius;

    # create an empty model instance -
    model = modeltype();
    rule = Dict{Int,Int}(); # key: neighborhood state, value: resulting state

    # TODO: build the rule dictionary from the index, colors, and radius values in the data NamedTuple
    number_of_states = colors^radius;
    rule_digits = digits(index, base=colors, pad=num_combinations);
    P = tuple(rule_digits)
    # TODO: Check out the `digits` function in Julia to help with this task
    for(i, j) in zip(0:number_of_states-1, states)
        rule[i] = j
    end
    # TODO: Make sure to comment out the throw statement below once you implement this functionality
    #throw(ErrorException("The rule dictionary construction from the index, colors, and radius values has not been implemented yet."));
    
    # set the data on the object
    model.index = index;
    model.rule = rule;
    model.radius = radius;
    model.number_of_colors = colors;

    # return
    return model;
end 







