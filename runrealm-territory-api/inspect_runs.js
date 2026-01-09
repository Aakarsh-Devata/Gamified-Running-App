import admin from 'firebase-admin';
import dotenv from 'dotenv';

dotenv.config();

// Initialize Firebase Admin
const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function inspectRunData() {
    try {
        console.log("Fetching runs from Firestore...\n");

        // Get all runs (limited to 5 for inspection)
        const runsSnapshot = await db.collection('runs').limit(5).get();

        if (runsSnapshot.empty) {
            console.log("No runs found in Firestore.");
            return;
        }

        console.log(`Found ${runsSnapshot.size} run(s)\n`);

        runsSnapshot.forEach((doc, index) => {
            const data = doc.data();
            console.log(`--- Run ${index + 1} (ID: ${doc.id}) ---`);
            console.log("Fields:", Object.keys(data));

            if (data.path) {
                console.log("Path exists:", Array.isArray(data.path));
                console.log("Path length:", data.path?.length);
                if (data.path?.length > 0) {
                    console.log("First point:", JSON.stringify(data.path[0]));
                    console.log("Last point:", JSON.stringify(data.path[data.path.length - 1]));
                }
            } else {
                console.log("No 'path' field found");
            }

            console.log("Distance:", data.distance);
            console.log("Duration:", data.duration);
            console.log("\n");
        });

    } catch (error) {
        console.error("Error inspecting run data:", error);
    } finally {
        process.exit(0);
    }
}

inspectRunData();
