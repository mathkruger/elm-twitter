import { initializeApp } from "firebase/app";
import { getAuth, signInWithPopup, signOut, GoogleAuthProvider, onAuthStateChanged } from "firebase/auth";

import { Elm } from "./Main.elm";

const firebaseConfig = {
    apiKey: "AIzaSyBWaCFRO0pjAovtpyzelr0JPseeTpoaC7c",
    authDomain: "elm-twitter.firebaseapp.com",
    projectId: "elm-twitter",
    storageBucket: "elm-twitter.appspot.com",
    messagingSenderId: "68333046704",
    appId: "1:68333046704:web:68ed6ea67e4f17cb9ee475"
};

const firebaseApp = initializeApp(firebaseConfig);

const provider = new GoogleAuthProvider();
const auth = getAuth();

const app = Elm.Main.init({
    node: document.getElementById("root")
});

app.ports.signIn.subscribe(async () => {
    try {
        const result = await signInWithPopup(auth, provider);
        const idToken = await result.user.getIdToken();

        console.log("photoUrl", result.user.photoURL)

        app.ports.signInInfo.send({
            token: idToken,
            email: result.user.email,
            displayName: result.user.displayName,
            photoURL: result.user.photoURL,
            uid: result.user.uid
        });
    } catch (error) {
        console.log(error);
        app.ports.signInError.send({
            code: error.code,
            message: error.message
        });
    }
});

app.ports.signOut.subscribe(() => {
    console.log("LogOut called");
    signOut(auth);
});