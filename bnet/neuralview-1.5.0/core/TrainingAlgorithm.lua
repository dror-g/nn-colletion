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
-- Representation of a training algorithm. Holds a list of properties that allows
-- the user to control the aspects of the algorithm.
-- @see core.NetworkParam
local TrainingAlgorithm, TrainingAlgorithmMT = nv_module('core.TrainingAlgorithm')

---
-- @name TrainingAlgorithm
-- @class table
-- @description Representation of a training algorithm.
-- @field name Localized name of the training algorithm
-- @field ftype FANN type of the training algorithm
-- @field params Array of NetworkParam

TrainingAlgorithm.names = {
    [fann.TRAIN_INCREMENTAL] = _"Incremental",
    [fann.TRAIN_BATCH] = _"Batch",
    [fann.TRAIN_RPROP] = _"RPROP",
    [fann.TRAIN_QUICKPROP] = _"Quickprop",
    [fann.TRAIN_SARPROP] = _"SARPROP",
}

---
-- Constructor.
--
-- @param ftype FANN type of the training algorithm
-- @return New TrainingAlgorithm instance 
function TrainingAlgorithm.new(ftype)
    local self = {}
    setmetatable(self, TrainingAlgorithmMT)
    
    self.name = TrainingAlgorithm.names[ftype]
    self.ftype = ftype
    self.params = {}
    
    return self
end

---
-- Adds training parameters to the algorithm.
--
-- @param ... Parameters to add
function TrainingAlgorithm:add_params(...)
    for i, param in ipairs({...}) do
        table.insert(self.params, param)
    end
end

return TrainingAlgorithm
