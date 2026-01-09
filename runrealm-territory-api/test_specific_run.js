import admin from 'firebase-admin';
import dotenv from 'dotenv';

dotenv.config();

// Initialize Firebase Admin
const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: `https://${serviceAccount.project_id}.firebaseio.com`
});

const db = admin.firestore();

// Fresh token from earlier
const ID_TOKEN = "eyJhbGciOiJSUzI1NiIsImtpZCI6IjQ1YTZjMGMyYjgwMDcxN2EzNGQ1Y2JiYmYzOWI4NGI2NzYxMjgyNjUiLCJ0eXAiOiJKV1QifQ.eyJwcm92aWRlcl9pZCI6ImFub255bW91cyIsImlzcyI6Imh0dHBzOi8vc2VjdXJldG9rZW4uZ29vZ2xlLmNvbS9ydW5yZWFsbSIsImF1ZCI6InJ1bnJlYWxtIiwiYXV0aF90aW1lIjoxNzY0MTQyMDU0LCJ1c2VyX2lkIjoid1dIM1JKMG93NGJ6dmdmYXJJQkVaak1OVlpyMiIsInN1YiI6IndXSDNSSjBvdzRienZnZmFySUJFWmpNTlZacjIiLCJpYXQiOjE3NjQxNDIwNTUsImV4cCI6MTc2NDE0NTY1NSwiZmlyZWJhc2UiOnsiaWRlbnRpdGllcyI6e30sInNpZ25faW5fcHJvdmlkZXIiOiJhbm9ueW1vdXMifX0.b11ss82XEs1obfnwWAODozIhNmj3ZGDJzKHxnUOGEpWmAq_e_HZKFWLSgnb_fa7EQm_cvw6ZF0Ragw-O1ujaaWHos2eWZ0LLbkL6C33OZQ0DdWNa7zia7qi20NeASnN6VNxvpmYG_wIIo9gixf6g3Me0mifdY0PuP55a_pZBZBNP11gxt1c_Aj40rVMq_6DHwnpK3_xNf_JJUe76kkY-bOYhNiyzik0WZOlf88l3735X7JuO7Al-ou_g-8NvS0whjKLkNtlwfiMIElRlAyPY6p3qzezk74dOgOpGttjBSm9TTDJD9E5TcmQEk-SA-mKWTuQhF2zwS5tqQ2TqZf5_xg";

const RUN_ID = "pdUPkQgpSxtbUK503cuo";

async function testSpecificRun() {
    try {
        console.log(`Fetching run ${RUN_ID} from Firestore...\n`);

        // Fetch specific document by ID
        const runDoc = await db.collection('runs').doc(RUN_ID).get();

        if (!runDoc.exists) {
            console.log("❌ Run not found!");
            process.exit(1);
        }

        const runData = runDoc.data();
        console.log("✅ Run found!");
        console.log("Fields:", Object.keys(runData));

        if (!runData.path || !Array.isArray(runData.path)) {
            console.log("❌ No valid path data in this run");
            process.exit(1);
        }

        console.log(`Path has ${runData.path.length} points\n`);

        // Normalize path format
        const path = runData.path.map(point => ({
            lat: point.lat || point.latitude,
            lng: point.lng || point.longitude
        }));

        console.log("First point:", path[0]);
        console.log("Last point:", path[path.length - 1]);
        console.log("\nSending to territory API...\n");

        // Send to API
        const url = 'http://localhost:8080/territories/create';
        const body = {
            path: path,
            runId: RUN_ID
        };

        const response = await fetch(url, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${ID_TOKEN}`
            },
            body: JSON.stringify(body)
        });

        const data = await response.json();
        console.log("Response status:", response.status);
        console.log("Response data:", JSON.stringify(data, null, 2));

        if (data.ok) {
            console.log("\n✅ SUCCESS: Territory created from real run!");
            console.log("Run ID:", RUN_ID);
            console.log("Territory ID:", data.territoryId);
            console.log("Area:", data.area_m2.toFixed(2), "sq meters");
            console.log("Area:", (data.area_m2 / 1000000).toFixed(4), "sq kilometers");
            console.log("\n🎉 Complete data flow verified:");
            console.log("  Firebase → Node API → PostGIS ✓");
        } else {
            console.log("\n❌ FAILURE:", data.error);
        }

    } catch (error) {
        console.error("❌ Error:", error.message);
    } finally {
        process.exit(0);
    }
}

testSpecificRun();
