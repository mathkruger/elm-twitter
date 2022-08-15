import { initializeApp } from "firebase/app";
import { getAuth, signInWithPopup, signOut, GoogleAuthProvider, onAuthStateChanged } from "firebase/auth";
import { query, getFirestore, collection, addDoc, doc, orderBy, onSnapshot, deleteDoc, setDoc, where, getDocs, getDoc } from "firebase/firestore";

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
const db = getFirestore();

const app = Elm.Main.init({
    node: document.getElementById("root")
});

const sendUserInfo = async (user) => {
    const idToken = await user.getIdToken();

    const object = {
        token: idToken,
        email: user.email,
        displayName: user.displayName,
        photoURL: user.photoURL,
        uid: user.uid
    }

    app.ports.signInInfo.send(object);
}

const sendError = (error) => {
    console.log(error);
    app.ports.signInError.send({
        code: error.code,
        message: error.message
    });
}

const sendTweets = (tweets) => {
    app.ports.receiveTweets.send(tweets);
}

const sendLikes = (likes) => {
    app.ports.receiveLikes.send(likes);
}

const subscribeForTweets = () => {
    const q = query(collection(db, "tweets"), orderBy("date", "desc"));
    onSnapshot(q, (querySnapshot) => {
        const tweets = [];
        
        querySnapshot.forEach(x => {
            const line = x.data();
            line.uid = x.id;
            line.formatedDate = new Date(line.date).toLocaleString();
            tweets.push(line);
        });

        sendTweets(tweets);
    });
}

const subscribeForLikes = () => {
    const q = query(collection(db, "likes"));
    onSnapshot(q, (querySnapshot) => {
        const likes = [];

        querySnapshot.forEach(doc => {
            const line = doc.data();
            line.uid = doc.id;

            likes.push(line);
        });

        sendLikes(likes);
    })
}

app.ports.signIn.subscribe(async () => {
    try {
        const result = await signInWithPopup(auth, provider);
        await sendUserInfo(result.user);
    } catch (error) {
        sendError(error);
    }
});

app.ports.signOut.subscribe(() => {
    signOut(auth);
});

app.ports.sendTweet.subscribe(async (data) => {
    try {
        data.date = Date.now();
        await addDoc(collection(db, "tweets"), data)
    } catch (error) {
        sendError(error);
    }
});

app.ports.deleteTweet.subscribe(async (id) => {
    try {
        await deleteDoc(doc(collection(db, "tweets"), id));

        // removing likes attached to the tweet
        const q = query(collection(db, "likes"), 
            where("tweetUid", "==", id));
        
        const likes = await getDocs(q);
        likes.forEach(async item => {
            await deleteDoc(doc(collection(db, "likes"), item.id));
        });
    } catch (error) {
        sendError(error);
    }
});

app.ports.likeTweet.subscribe(async (ids) => {
    const userUid = ids[0];
    const tweetUid = ids[1];

    try {
        const q = query(collection(db, "likes"), 
            where("tweetUid", "==", tweetUid), 
            where("userUid", "==", userUid));
        
        const likes = await getDocs(q);

        if (likes.size > 0) {
            // remove like
            const id = likes.docs[0].id;
            await deleteDoc(doc(collection(db, "likes"), id));
        }
        else {
           // add like 
            await addDoc(collection(db, "likes"), {
                userUid,
                tweetUid
            });
        }
    } catch (error) {
        sendError(error);
    }
});

onAuthStateChanged(auth, async (user) => {
    try {
        if (user) {
            await sendUserInfo(user);

            subscribeForTweets();
            subscribeForLikes();
        }
    } catch (error) {
        sendError(error);
    }
});
