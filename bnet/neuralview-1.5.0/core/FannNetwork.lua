--[[
    This file is part of NeuralView.

    NeuralView is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    NeuralView is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with NeuralView.  If not, see <http://www.gnu.org/licenses/>.
--]]

---
-- Implementation of the FANN parameters and training algorithms.
-- @see core.TrainingAlgorithm
local FannNetwork, FannNetworkMT = nv_module('core.FannNetwork')

local Param = require('core.NetworkParam')
local Algo = require('core.TrainingAlgorithm')
local net = fann.Net

-- To make code cleaner
local INCREMENTAL = fann.TRAIN_INCREMENTAL
local BATCH       = fann.TRAIN_BATCH
local RPROP       = fann.TRAIN_RPROP
local QUICKPROP   = fann.TRAIN_QUICKPROP
local SARPROP     = fann.TRAIN_SARPROP

-- Wrapper functions

-- Get the training algorithm as a string
local function get_training_algorithm(net)
    local algo = net:get_training_algorithm()
    return Algo.names[algo]
end

-- Get the connection rate as a %
local function get_connection_rate(net)
    local rate = net:get_connection_rate()
    return string.format('%.2f%%', rate * 100)
end

-- Get the number of neurons in each layer
local function get_neurons_per_layer(net)
    local array = net:get_layer_array()
    return table.concat(array, ', ')
end

-- Get the number of bias neurons in each layer
local function get_bias_per_layer(net)
    local array = net:get_bias_array()
    return table.concat(array, ', ')
end

-- Function wrapper to get the result as an integer
local function int(f)
    return function(...) return string.format('%.0f', f(...)) end
end

local net_types = {
    [fann.NETTYPE_LAYER] = _"Layer",
    [fann.NETTYPE_SHORTCUT] = _"Shortcut",
}

-- Get the network type
local function get_network_type(net)
    local ntype = net:get_network_type()
    return net_types[ntype]
end

---
-- @name FannNetwork
-- @class table
-- @description FANN training algorithms and parameters.
-- @field params Map of NetworkParam, indexed by the name (like learning_rate)
-- @field algorithms Map of algorithms, index by its FANN id
-- @field algorithms_array Array of the supported algorithms  
-- @field general_params Array, like algorithms_array, but with the general
-- @field activation_functions Table in the form { names, values }, where names[n]
-- is the name for values[n]
-- parameters like network type and connection rate

-- Some parameters, like learning_rate, are shared between algorithms.
local params = {

    -- training parameters
    learning_rate = Param.new_number(_"Learning rate",
        _"Factor that determines how aggressive the training should be",
        net.get_learning_rate, net.set_learning_rate, 0, 100),
    
    learning_momentum = Param.new_number(_"Learning momentum",
        _"Momentum term",
        net.get_learning_momentum, net.set_learning_momentum, 0, 100),
    
    rprop_increase_factor = Param.new_number(_"Increase factor",
        _"Increase factor of the training step-size",
        net.get_rprop_increase_factor, net.set_rprop_increase_factor, 1, 100),
        
    rprop_decrease_factor = Param.new_number(_"Decrease factor",
        _"Decrease factor of the step-size",
        net.get_rprop_decrease_factor, net.set_rprop_decrease_factor, 0, 1),
    
    rprop_delta_min = Param.new_number(_"Delta min",
        _"Minimum value of the step-size",
        net.get_rprop_delta_min, net.set_rprop_delta_min, 0, 1),
    
    rprop_delta_max = Param.new_number(_"Delta max",
        _"Maximum value of the step-size",
        net.get_rprop_delta_max, net.set_rprop_delta_max, 1, 1000),
    
    rprop_delta_zero = Param.new_number(_"Delta zero",
        _"Initial value of the step-size",
        net.get_rprop_delta_zero, net.set_rprop_delta_zero, 0, 1000),
    
    quickprop_decay = Param.new_number(_"Decay",
        _"Decrease factor of the connection weights",
        net.get_quickprop_decay, net.set_quickprop_decay, -1, 0),
    
    quickprop_mu = Param.new_number(_"Mu",
        _"Increase/decrease factor of the step-size",
        net.get_quickprop_mu, net.set_quickprop_mu, 1, 100),
    
    sarprop_weight_decay_shift = Param.new_number(_"Weight decay shift",
        _"SARPROP weight decay shift",
        net.get_sarprop_weight_decay_shift, net.set_sarprop_weight_decay_shift, -1000, 1000),
    
    sarprop_step_error_threshold_factor = Param.new_number(_"Step error threshold factor",
        _"SARPROP step error threshold factor",
        net.get_sarprop_step_error_threshold_factor, net.set_sarprop_step_error_threshold_factor, 0, 100),
    
    sarprop_step_error_shift = Param.new_number(_"Step error shift",
        _"SARPROP step error shift",
        net.get_sarprop_step_error_shift, net.set_sarprop_step_error_shift, 0, 100),
        
    sarprop_temperature = Param.new_number(_"Temperature",
        _"SARPROP temperature",
        net.get_sarprop_temperature, net.set_sarprop_temperature, 0, 100),
    
    -- general parameters
    network_type = Param.new_readonly(_"Network type",
        _"Network connection type",
        get_network_type),
    
    connection_rate = Param.new_readonly(_"Connection rate",
        _"Network connection rate",
        get_connection_rate),
    
    total_neurons = Param.new_readonly(_"Total neurons",
        _"Total number of neurons in the network",
        int(net.get_total_neurons) ),
    
    total_connections = Param.new_readonly(_"Total connections",
        _"Total number of connections in the network",
        int(net.get_total_connections) ),
    
    neurons_per_layer = Param.new_readonly(_"Neurons per layer",
        _"Number of neurons per layer",
        get_neurons_per_layer),
    
    bias_per_layer = Param.new_readonly(_"Bias per layer",
        _"Number of bias neurons per layer",
        get_bias_per_layer),
    
    training_algorithm = Param.new_readonly(_"Training algorithm",
        _"Selected training algorithm",
        get_training_algorithm),
    
    training_algorithm_option = Param.new_option(_"Algorithm",
        _"Training algorithm",
        net.get_training_algorithm,
        net.set_training_algorithm, {
            ['names'] = {
                Algo.names[INCREMENTAL],
                Algo.names[BATCH],
                Algo.names[RPROP],
                Algo.names[QUICKPROP],
                Algo.names[SARPROP]
            },
            
            ['values'] = {INCREMENTAL, BATCH, RPROP, QUICKPROP, SARPROP},
        }),
}

local algorithms = {
    [INCREMENTAL] = Algo.new(INCREMENTAL),
    [BATCH]       = Algo.new(BATCH),
    [RPROP]       = Algo.new(RPROP),
    [QUICKPROP]   = Algo.new(QUICKPROP),
    [SARPROP]     = Algo.new(SARPROP),
}

algorithms[INCREMENTAL]:add_params(
    params.learning_rate, params.learning_momentum
)

algorithms[BATCH]:add_params(
    params.learning_rate
)

algorithms[QUICKPROP]:add_params(
    params.learning_rate, params.quickprop_decay, params.quickprop_mu
)

algorithms[RPROP]:add_params(
    params.rprop_increase_factor, params.rprop_decrease_factor,
    params.rprop_delta_min, params.rprop_delta_max, params.rprop_delta_zero
)

algorithms[SARPROP]:add_params(
    params.rprop_increase_factor, params.rprop_decrease_factor,
    params.rprop_delta_min, params.rprop_delta_max, params.rprop_delta_zero,
    params.sarprop_weight_decay_shift, params.sarprop_step_error_threshold_factor,
    params.sarprop_step_error_shift, params.sarprop_temperature
)

FannNetwork.params = params

FannNetwork.algorithms = algorithms

FannNetwork.algorithms_array = {
    algorithms[INCREMENTAL], algorithms[BATCH],
    algorithms[RPROP], algorithms[QUICKPROP],
    algorithms[SARPROP]
}

FannNetwork.general_params = {
    params.network_type, params.connection_rate, 
    params.neurons_per_layer, params.bias_per_layer,
    params.total_neurons, params.total_connections,
    params.training_algorithm, 
}

FannNetwork.activation_functions = {
    names = {
        _"Linear", _"Linear piece", _"Linear piece symmetric",
        _"Threshold", _"Threshold symmetric",
        _"Sigmoid", _"Sigmoid stepwise", _"Sigmoid symmetric",
        _"Gaussian", _"Gaussian symmetric",
        _"Elliot", _"Elliot symmetric", 
        _"Sin", _"Sin symmetric", _"Cos", _"Cos symmetric"
    },
    
    values = {
        fann.LINEAR, fann.LINEAR_PIECE, fann.LINEAR_PIECE_SYMMETRIC,
        fann.THRESHOLD, fann.THRESHOLD_SYMMETRIC,
        fann.SIGMOID, fann.SIGMOID_STEPWISE, fann.SIGMOID_SYMMETRIC,
        fann.GAUSSIAN, fann.GAUSSIAN_SYMMETRIC,
        fann.ELLIOT, fann.ELLIOT_SYMMETRIC, 
        fann.SIN, fann.SIN_SYMMETRIC, fann.COS, fann.COS_SYMMETRIC
    }
}

return FannNetwork
