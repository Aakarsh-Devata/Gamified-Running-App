// Using built-in fetch API in Node.js v18+

// The token captured from the previous step
const ID_TOKEN = "eyJhbGciOiJSUzI1NiIsImtpZCI6IjQ1YTZjMGMyYjgwMDcxN2EzNGQ1Y2JiYmYzOWI4NGI2NzYxMjgyNjUiLCJ0eXAiOiJKV1QifQ.eyJwcm92aWRlcl9pZCI6ImFub255bW91cyIsImlzcyI6Imh0dHBzOi8vc2VjdXJldG9rZW4uZ29vZ2xlLmNvbS9ydW5yZWFsbSIsImF1ZCI6InJ1bnJlYWxtIiwiYXV0aF90aW1lIjoxNzY0MTQyMDU0LCJ1c2VyX2lkIjoid1dIM1JKMG93NGJ6dmdmYXJJQkVaak1OVlpyMiIsInN1YiI6IndXSDNSSjBvdzRienZnZmFySUJFWmpNTlZacjIiLCJpYXQiOjE3NjQxNDIwNTUsImV4cCI6MTc2NDE0NTY1NSwiZmlyZWJhc2UiOnsiaWRlbnRpdGllcyI6e30sInNpZ25faW5fcHJvdmlkZXIiOiJhbm9ueW1vdXMifX0.b11ss82XEs1obfnwWAODozIhNmj3ZGDJzKHxnUOGEpWmAq_e_HZKFWLSgnb_fa7EQm_cvw6ZF0Ragw-O1ujaaWHos2eWZ0LLbkL6C33OZQ0DdWNa7zia7qi20NeASnN6VNxvpmYG_wIIo9gixf6g3Me0mifdY0PuP55a_pZBZBNP11gxt1c_Aj40rVMq_6DHwnpK3_xNf_JJUe76kkY-bOYhNiyzik0WZOlf88l3735X7JuO7Al-ou_g-8NvS0whjKLkNtlwfiMIElRlAyPY6p3qzezk74dOgOpGttjBSm9TTDJD9E5TcmQEk-SA-mKWTuQhF2zwS5tqQ2TqZf5_xg";

async function testCreateTerritory() {
    const url = 'http://localhost:8080/territories/create';

    // A simple square path
    const path = [
        { lat: 37.7749, lng: -122.4194 },
        { lat: 37.7749, lng: -122.4100 },
        { lat: 37.7650, lng: -122.4100 },
        { lat: 37.7650, lng: -122.4194 },
        { lat: 37.7749, lng: -122.4194 } // Closing the loop (optional as API handles it, but good practice)
    ];

    const body = {
        path: path,
        runId: "test_run_123"
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
            console.log("SUCCESS: Territory created!");
            console.log("Area:", data.area_m2, "sq meters");
        } else {
            console.log("FAILURE:", data.error);
        }

    } catch (error) {
        console.error("Error executing test:", error);
    }
}

testCreateTerritory();
