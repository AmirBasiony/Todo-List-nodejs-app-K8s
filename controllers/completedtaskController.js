const db = require('../config/mongoose');
const Dashboard = require('../models/dashboard');
const User = require('../models/register');

module.exports.completedtask = function(req, res) {
    Dashboard.find({})
    .then(function(data) {
        return User.findOne({ email: "ankitvis609@gmail.com" })
        .then(function(user) {
            if (!user || !user.name) {
                console.log("**********user is null or name missing");
                return res.status(404).send("User not found");
            }

            console.log(`**********user`, user.name);
            return res.render('completedtask', {
                title: "Dashboard",
                name: user.name,
                dashboard: data
            });
        });
    })
    .catch(function(err) {
        console.log('Error', err);
        res.status(500).send("Internal Server Error");
    });
};
