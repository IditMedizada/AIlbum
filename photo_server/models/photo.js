const mongoose = require('mongoose');
const Schema = mongoose.Schema;

const face = new Schema({
    id: {
        type: Number,
        required: true
    },
});

const Photo = new Schema({
    photo: {
        type: String,
        required: true
    },
    originalName: {
        type: String,
        require: true
    },
    created: {
        type: Date,
        default: Date.now
    },
    date: {
        type: Date
    },
    faces: [face]
   

});


const photoSchema  = mongoose.model('Photo', Photo);

module.exports = photoSchema ;