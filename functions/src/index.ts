import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp(functions.config().firebase);

import { DocumentData } from "@google-cloud/firestore";
import { playMove, forfeit } from "./play_move";
import { queuePlayer } from "./queue_player";
import { getActiveMatches } from "./get_active_matches";
import { reconnect } from "./reconnect";

exports.queuePlayer = functions
  .region("europe-west1")
  .https.onRequest(async (request, response) => queuePlayer(request, response));

exports.playMove = functions
  .region("europe-west1")
  .https.onRequest(async (request, response) => playMove(request, response));

exports.forfeit = functions
  .region("europe-west1")
  .https.onRequest(async (request, response) => forfeit(request, response));

exports.getActiveMatches = functions
  .region("europe-west1")
  .https.onRequest(async (request, response) =>
    getActiveMatches(request, response)
  );

exports.reconnect = functions
  .region("europe-west1")
  .https.onRequest(async (request, response) => reconnect(request, response));

exports.notifyUser = functions
  .region("europe-west1")
  .firestore.document("matches/{matchId}")
  .onUpdate((change, context) => {
    const newMatch = change.after.data();
    const oldMatch = change.before.data();
    if (newMatch != null && oldMatch != null) {
      if (newMatch.joinuid != oldMatch.joinuid) {
        onMatchStart(context.params.matchId);
      }
      if (newMatch.hosttarget != oldMatch.hosttarget) {
        onMove(newMatch, context.params.matchId, true);
      }
      if (newMatch.jointarget != oldMatch.jointarget) {
        onMove(newMatch, context.params.matchId, false);
      }
      if (newMatch.winner != oldMatch.winner) {
        onWinner(newMatch, context.params.matchId);
      }
    }
    return true;
  });

let matches = admin.firestore().collection("matches");
let users = admin.firestore().collection("users");

async function onMatchStart(matchId: string) {
  let matchDoc = await matches.doc(matchId).get();
  let hostDoc = await users.where("uid", "==", matchDoc.data()!.hostuid).get();
  let hostName = await hostDoc.docs[0].data().username;
  let joinDoc = await users.where("uid", "==", matchDoc.data()!.joinuid).get();
  let joinName = await joinDoc.docs[0].data().username;
  let messageToHost = {
    data: {
      matchid: matchDoc.id,
      click_action: "FLUTTER_NOTIFICATION_CLICK",
      messType: "challenge",
      enemyName: joinName
    },
    notification: {
      title: "Match started!",
      body: joinName + " challenged you!"
    }
  };
  let messageToJoin = {
    data: {
      matchid: matchDoc.id,
      click_action: "FLUTTER_NOTIFICATION_CLICK",
      messType: "challenge",
      enemyName: hostName
    },
    notification: {
      title: "Match started!",
      body: hostName + " challenged you!"
    }
  };
  let options = {
    priority: "high",
    timeToLive: 60 * 60 * 24
  };
  try {
    admin
      .messaging()
      .sendToDevice(matchDoc.data()!.hostfcmtoken, messageToHost, options);
    console.log("message sent to host: " + matchDoc.data()!.hostfcmtoken);
  } catch (e) {
    console.log("--- error sending message: ");
    console.error(Error(e));
  }
  try {
    admin
      .messaging()
      .sendToDevice(matchDoc.data()!.joinfcmtoken, messageToJoin, options);
    console.log("message sent to join: " + matchDoc.data()!.joinfcmtoken);
  } catch (e) {
    console.log("--- error sending message: ");
    console.error(Error(e));
  }
}

function onMove(newMatch: DocumentData, matchId: string, hostOrJoin: boolean) {
  let message = {
    data: {
      matchid: matchId,
      enemytarget: hostOrJoin ? newMatch.hosttarget : newMatch.jointarget,
      messType: "move"
    }
  };
  let options = {
    priority: "high",
    timeToLive: 60 * 60 * 24
  };
  try {
    admin
      .messaging()
      .sendToDevice(
        hostOrJoin ? newMatch.joinfcmtoken : newMatch.hostfcmtoken,
        message,
        options
      );
  } catch (e) {
    console.log("--- error sending message");
    console.error(Error(e));
  }
}

function onWinner(newMatch: DocumentData, matchId: string) {
  let messageToJoin = {
    data: {
      matchid: matchId,
      winner: newMatch.winner,
      messType: "winner",
      winnername: newMatch.winnername,
      forfeitwin: newMatch.forfeitwin.toString()
    },
    notification: {
      title: "Match finished!",
      body: newMatch.winnername + " won!"
    }
  };
  let messageToHost = {
    data: {
      matchid: matchId,
      winner: newMatch.winner,
      messType: "winner",
      winnername: newMatch.winnername,
      forfeitwin: newMatch.forfeitwin.toString()
    },
    notification: {
      title: "Match finished!",
      body: newMatch.winnername + " won!"
    }
  };
  let options = {
    priority: "high",
    timeToLive: 60 * 60 * 24
  };
  try {
    admin
      .messaging()
      .sendToDevice(newMatch.joinfcmtoken, messageToJoin, options);
  } catch (e) {
    console.log("--- error sending message");
    console.error(Error(e));
  }
  try {
    admin
      .messaging()
      .sendToDevice(newMatch.hostfcmtoken, messageToHost, options);
  } catch (e) {
    console.log("--- error sending message");
    console.error(Error(e));
  }
}
