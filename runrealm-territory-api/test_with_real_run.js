// Test script for territory creation using real Firebase run data
//
// INSTRUCTIONS:
// 1. Go to Firebase Console: https://console.firebase.google.com/project/runrealm/firestore
// 2. Navigate to the 'runs' collection
// 3. Click on any run document
// 4. Copy the 'path' field value (it should be an array of lat/lng objects)
// 5. Paste it below in the PASTE_PATH_HERE section
// 6. Run: node test_with_real_run.js

// Using built-in fetch API in Node.js v18+

// The fresh token
const ID_TOKEN = "eyJhbGciOiJSUzI1NiIsImtpZCI6IjQ1YTZjMGMyYjgwMDcxN2EzNGQ1Y2JiYmYzOWI4NGI2NzYxMjgyNjUiLCJ0eXAiOiJKV1QifQ.eyJwcm92aWRlcl9pZCI6ImFub255bW91cyIsImlzcyI6Imh0dHBzOi8vc2VjdXJldG9rZW4uZ29vZ2xlLmNvbS9ydW5yZWFsbSIsImF1ZCI6InJ1bnJlYWxtIiwiYXV0aF90aW1lIjoxNzY0MTQyMDU0LCJ1c2VyX2lkIjoid1dIM1JKMG93NGJ6dmdmYXJJQkVaak1OVlpyMiIsInN1YiI6IndXSDNSSjBvdzRienZnZmFySUJFWmpNTlZacjIiLCJpYXQiOjE3NjQxNDIwNTUsImV4cCI6MTc2NDE0NTY1NSwiZmlyZWJhc2UiOnsiaWRlbnRpdGllcyI6e30sInNpZ25faW5fcHJvdmlkZXIiOiJhbm9ueW1vdXMifX0.b11ss82XEs1obfnwWAODozIhNmj3ZGDJzKHxnUOGEpWmAq_e_HZKFWLSgnb_fa7EQm_cvw6ZF0Ragw-O1ujaaWHos2eWZ0LLbkL6C33OZQ0DdWNa7zia7qi20NeASnN6VNxvpmYG_wIIo9gixf6g3Me0mifdY0PuP55a_pZBZBNP11gxt1c_Aj40rVMq_6DHwnpK3_xNf_JJUe76kkY-bOYhNiyzik0WZOlf88l3735X7JuO7Al-ou_g-8NvS0whjKLkNtlwfiMIElRlAyPY6p3qzezk74dOgOpGttjBSm9TTDJD9E5TcmQEk-SA-mKWTuQhF2zwS5tqQ2TqZf5_xg";

// TODO: PASTE YOUR RUN'S PATH DATA HERE
// Example format: [{ latitude: 37.7749, longitude: -122.4194 }, ...]
// OR: [{ lat: 37.7749, lng: -122.4194 }, ...]
const REAL_RUN_PATH = [
    { lat: 37.7749, lng: -122.4194 },
    { lat: 37.7750, lng: -122.4194 },
    { lat: 37.7750, lng: -122.4195 },
    { lat: 37.7749, lng: -122.4195 },
    { lat: 37.7749, lng: -122.4194 } // Close loop
];

async function testWithRealRun() {
    if (REAL_RUN_PATH.length === 0) {
        console.log("❌ ERROR: No path data provided!");
        console.log("\nPlease:");
        console.log("1. Go to Firebase Console: https://console.firebase.google.com/project/runrealm/firestore");
        console.log("2. Open the 'runs' collection");
        console.log("3. Click on any run document");
        console.log("4. Copy the 'path' array");
        console.log("5. Paste it in this file where it says 'PASTE PATH DATA HERE'");
        console.log("6. Run: node test_with_real_run.js\n");
        return;
    }

    const url = 'http://localhost:8080/territories/create';

    // Normalize path data (handle both lat/lng and latitude/longitude formats)
    const path = REAL_RUN_PATH.map(point => ({
        lat: point.lat || point.latitude,
        lng: point.lng || point.longitude
    }));

    console.log(`Testing with ${path.length} path points from real run data\n`);

    const body = {
        path: path,
        runId: "real_run_test_" + Date.now()
    };

    try {
        console.log("Sending request to", url);
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
            console.log("\n✅ SUCCESS: Territory created from real run data!");
            console.log("Territory ID:", data.territoryId);
            console.log("Area:", data.area_m2, "sq meters");
            console.log("Area:", (data.area_m2 / 1000000).toFixed(2), "sq kilometers");
        } else {
            console.log("\n❌ FAILURE:", data.error);
        }

    } catch (error) {
        console.error("\n❌ Error executing test:", error.message);
    }
}

testWithRealRun();
