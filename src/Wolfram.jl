# -- PRIVATE API BELOW HERE ------------------------------------------------------------------------ #
function _simulate(algorithm::WolframDeterministicSimulation, rulemodel::MyOneDimensionalElementaryWolframRuleModel, initial::Array{Int64,1}; 
    steps::Int64 = 240, maxnumberofmoves::Union{Int64, Nothing} = nothing, 
    parameters::Union{Nothing, Dict{Int, Float64}} = nothing,
    cooldownlength::Int64 = 0)::Dict{Int64, Array{Int64,2}}
    
    # get stuff from model -
    radius = rulemodel.radius; # how many cells am I looking at?
    number_of_colors = rulemodel.number_of_colors; # how many colors (states) can each cell have?
    width = length(initial); # how many cells are there?

    # initialize -
    frames = Dict{Int64, Array{Int64,2}}();
    frame = Array{Int64,2}(undef, steps, width) |> X -> fill!(X, 0);

    # set the initial state -
    foreach(i -> frame[1,i] = initial[i], 1:width);    
    frames[1] = frame; # set the initial frame -
    
    # TODO: implement the simulation run loop for the deterministic simulation here
    for step in 2:steps
    # Current frame reset
    frame = similar(frame)
    for i in 1:width
        # Determine neighborhood state
        neighborhood_states = []
        for offset in -radius:radius
            idx = mod1(i + offset, width) # Wrap-around boundary
            push!(neighborhood_states, frames[step-1][1, idx])
        end
        
        # Compute neighborhood integer index in base "colors"
        neighborhood_index = 0
        for (pos, state) in enumerate(reverse(neighborhood_states))
            neighborhood_index += state * colors^(pos-1)
        end
        
        # Apply rule to get next state
        frame[1, i] = get(rule, neighborhood_index, 0)  # Default 0 if missing
    end
    frames[step] = copy(frame)
end

    # TODO: Make sure to comment out the throw statement below once you implement this functionality
    throw(ErrorException("The simulation run loop for the deterministic simulation has not been implemented yet."));
    

    # return
    return frames;
end

function _simulate(algorithm::WolframStochasticSimulation, rulemodel::MyOneDimensionalElementaryWolframRuleModel, initial::Array{Int64,1}; 
    steps::Int64 = 240, maxnumberofmoves::Union{Int64, Nothing} = nothing, 
    parameters::Union{Nothing, Dict{Int, Float64}} = nothing,
    cooldownlength::Int64 = 0)::Dict{Int64, Array{Int64,2}}

    # get stuff from model
    radius = rulemodel.radius; # how many cells am I looking at?
    number_of_colors = rulemodel.number_of_colors; # how many colors (states) can each cell have?
    width = length(initial); # how many cells are there?
    q = Queue{Int64}(); # which cells will update?

    # initialize -
    frames = Dict{Int64, Array{Int64,2}}();
    frame = Array{Int64,2}(undef, steps, width) |> X -> fill!(X, 0);

    # cooldown -
    cooldown = Dict{Int64, Int64}(); # cooldown for each cell
    foreach(i -> cooldown[i] = 0, 1:width); # initialize cooldown for each cell

    # set the initial state -
    foreach(i -> frame[1,i] = initial[i], 1:width);    
    frames[1] = frame; # set the initial frame

    # TODO: implement the simulation run loop for the stochastic simulation here
    using Random
for step in 2:steps
    frame = similar(frame)
    copyto!(frame, frames[step-1])
    
    n_moves = 0
    moves_this_step = 0
    
    # Initialize queue with all cells - or refill from previous step if used
    isempty(q) && foreach(i -> enqueue!(q, i), 1:width)
    
    while !isempty(q) && (n_moves < maxnumberofmoves || maxnumberofmoves === nothing)
        cell = dequeue!(q)
        
        # Check cooldown
        if cooldown[cell] > 0
            cooldown[cell] -= 1
            enqueue!(q, cell)  # Re-queue for later
            continue
        end
        
        # Determine neighborhood states
        neighborhood_states = []
        for offset in -radius:radius
            idx = mod1(cell + offset, width)
            push!(neighborhood_states, frame[1, idx])
        end
        
        # Compute neighborhood index
        neighborhood_index = 0
        for (pos, state) in enumerate(reverse(neighborhood_states))
            neighborhood_index += state * colors^(pos-1)
        end
        
        current_state = frame[1, cell]
        next_state = current_state
        
        if isnothing(parameters)
            # Deterministic update using rule
            next_state = get(rule, neighborhood_index, current_state)
        else
            # Stochastic update: probabilities from parameters, fallback deterministic
            if haskey(parameters, neighborhood_index)
                p = parameters[neighborhood_index]
                next_state = rand() < p ? get(rule, neighborhood_index, current_state) : current_state
            else
                next_state = get(rule, neighborhood_index, current_state)
            end
        end
        
        # Update state if changed
        if next_state != current_state
            frame[1, cell] = next_state
            cooldown[cell] = cooldown[cell] + cooldownlength  # Set cooldown timer
            n_moves += 1
            moves_this_step += 1
        end
        
        # Re-queue neighbors for possible update
        for offset in -radius:radius
            idx = mod1(cell + offset, width)
            enqueue!(q, idx)
        end
        
        if maxnumberofmoves !== nothing && n_moves >= maxnumberofmoves
            break
        end
    end
    
    frames[step] = copy(frame)
end

    # TODO: Make sure to comment out the throw statement below once you implement this functionality
    throw(ErrorException("The simulation run loop for the stochastic simulation has not been implemented yet."));
    
    # return
    return frames;
end
# -- PRIVATE API ABOVE HERE ------------------------------------------------------------------------ #


# -- PUBLIC API BELOW HERE ------------------------------------------------------------------------ #
"""
    function simulate(rulemodel::MyOneDimensionalElementaryWolframRuleModel, initial::Array{Int64,1};
        steps::Int64 = 24, maxnumberofmoves::Union{Int64, Nothing} = nothing, 
        algorithm::AbstractWolframSimulationAlgorithm)) -> Dict{Int64, Array{Int64,2}}

The simulate function runs a Wolfram simulation based on the provided rule model and initial state.

### Arguments
- `rulemodel::MyOneDimensionalElementaryWolframRuleModel`: The rule model to use for the simulation.
- `initial::Array{Int64,1}`: The initial state of the simulation.
- `steps::Int64`: The number of steps to simulate.
- `maxnumberofmoves::Union{Int64, Nothing}`: The maximum number of moves to simulate.
- `algorithm::AbstractWolframSimulationAlgorithm`: The algorithm to use for the simulation.

### Returns
- A dictionary mapping step numbers to the state of the simulation at that step.
"""
function simulate(rulemodel::MyOneDimensionalElementaryWolframRuleModel, initial::Array{Int64,1}; 
    steps::Int64 = 24, maxnumberofmoves::Union{Int64, Nothing} = nothing, 
    cooldownlength::Int64 = 0, parameters::Union{Nothing, Dict{Int, Float64}} = nothing,
    algorithm::AbstractWolframSimulationAlgorithm)::Dict{Int64, Array{Int64,2}}

    return _simulate(algorithm, rulemodel, initial; steps=steps, 
        maxnumberofmoves=maxnumberofmoves, cooldownlength=cooldownlength, parameters=parameters);
end
# -- PUBLIC API ABOVE HERE ------------------------------------------------------------------------ #