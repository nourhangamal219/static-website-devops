// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

var examplecorp = window.examplecorp || {};

(function scopeWrapper($) {
    
    var poolData = {
        UserPoolId: _config.cognito.userPoolId,
        ClientId: _config.cognito.userPoolClientId
    };

    var userPool = new AmazonCognitoIdentity.CognitoUserPool(poolData);

    if (typeof AWSCognito !== 'undefined') {
        AWSCognito.config.region = _config.cognito.region;
    }

    examplecorp.authToken = new Promise(function fetchCurrentAuthToken(resolve, reject) {
        var cognitoUser = userPool.getCurrentUser();

        if (cognitoUser) {
            cognitoUser.getSession(function sessionCallback(err, session) {
                if (err) {
                    reject(err);
                } else if (!session.isValid()) {
                    resolve(null);
                } else {
                    resolve(session.getIdToken().getJwtToken());
                }
            });
        } else {
            resolve(null);
        }
    });
    
    function register(email, password, onSuccess, onFailure) {
        var dataEmail = {
            Name: 'email',
            Value: email
        };
        var attributeEmail = new AmazonCognitoIdentity.CognitoUserAttribute(dataEmail);

        userPool.signUp(email, password, [attributeEmail], null,
            function signUpCallback(err, result) {
                if (!err) {
                    onSuccess(result);
                } else {
                    onFailure(err);
                }
            }
        );
    }

    function signin(email, password, onSuccess, onFailure) {
        var authenticationDetails = new AmazonCognitoIdentity.AuthenticationDetails({
            Username: email,
            Password: password
        });

        var cognitoUser = createCognitoUser(email);
        cognitoUser.authenticateUser(authenticationDetails, {
            onSuccess: onSuccess,
            onFailure: onFailure
        });
    }

    function verify(email, code, onSuccess, onFailure) {
        createCognitoUser(email).confirmRegistration(code, true, function confirmCallback(err, result) {
            if (!err) {
                onSuccess(result);
            } else {
                onFailure(err);
            }
        });
    }

    function createCognitoUser(email) {
        return new AmazonCognitoIdentity.CognitoUser({
            Username: email,
            Pool: userPool
        });
    }

    $(function onDocReady() {
        $('#signinForm').submit(handleSignin);
        $('#registrationForm').submit(handleRegister);
        $('#verifyForm').submit(handleVerify);
    });
    function examplecorpURLGenCall(authToken){
        $.ajax({
            method: 'POST',
            url: _config.api.invokeUrl + '/auth',
            headers: {
                Authorization: authToken
            },
            contentType: 'application/json',
            success: function(response, status){
                console.log('Status: ' + status + '.' + ' API Gatway call was successful, redirecting to examplecorp Streaming URL.')
                window.location.href = response.Message;
            },
            error: function(response, status){
                console.log('Status: ' + status + '.');
                console.log(response);
                alert('Amazon API Gateway can’t process the request right now because of an internal error. Try again later.');
                window.location.href = 'signin.html';
            }
        }); 
    }
    function handleSignin(event) {
        var email = $('#emailInputSignin').val();
        var password = $('#passwordInputSignin').val();
        event.preventDefault();
        signin(email, password,
            function signinSuccess() {
                var authToken;
                examplecorp.authToken.then(function setAuthToken(token) {
                    if (token) {
                        console.log('Auth token set.');
                        authToken = token;
                        examplecorpURLGenCall(authToken);
                    } else if(!token) {
                        var cognitoUser = userPool.getCurrentUser();
                        if (cognitoUser != null) {
                            cognitoUser.getSession(function(err, session) {
                                if (err) {
                                    console.log(err);
                                    return;
                                }
                                else {
                                authToken = session.getIdToken().getJwtToken();
                                console.log("Refresh.")
                                }
                                examplecorpURLGenCall(authToken);
                            });
                        
                        }
                    } else {
                        alert("Amazon Cognito can’t process the sign-in request right now because of an internal error. Try again later.");
                        window.location.href = 'signin.html';
                    }
                }).catch(function handleTokenError(error) {
                    window.location.href = 'signin.html';
                    console.log('Error: ' + error)
                });
            },
            function signinError(err) {
                alert("Amazon Cognito can’t process the sign-in request right now because of an internal error. Try again later.");
                console.log(err)
            }
        );
    }

    function handleRegister(event) {
        var email = $('#emailInputRegister').val();
        var password = $('#passwordInputRegister').val();
        var password2 = $('#password2InputRegister').val();

        var onSuccess = function registerSuccess(result) {
            var cognitoUser = result.user;
            console.log('user name is ' + cognitoUser.getUsername());
            var confirmation = ('Registration successful. Redirecting to the verification page, please check your email for your verification code.');
            alert(confirmation)
            if (confirmation) {
                window.location.href = 'verify.html';
            }
        };
        var onFailure = function registerFailure(err) {
            alert(err);
        };
        event.preventDefault();

        if (password === password2) {
            register(email, password, onSuccess, onFailure);
        } else {
            alert('The passwords do not match');
        }
    }

    function handleVerify(event) {
        var email = $('#emailInputVerify').val();
        var code = $('#codeInputVerify').val();
        event.preventDefault();
        verify(email, code,
            function verifySuccess(result) {
                console.log('call result: ' + result);
                console.log('Successfully verified');
                alert('Verification successful. Now redirecting to the login page.');
                window.location.href = 'signin.html';
            },
            function verifyError(err) {
                alert(err);
            }
        );
    }
}(jQuery));