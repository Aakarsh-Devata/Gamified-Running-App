// Test the new create-from-run endpoint with a specific run ID

const ID_TOKEN = "eyJhbGciOiJSUzI1NiIsImtpZCI6IjQ1YTZjMGMyYjgwMDcxN2EzNGQ1Y2JiYmYzOWI4NGI2NzYxMjgyNjUiLCJ0eXAiOiJKV1QifQ.eyJwcm92aWRlcl9pZCI6ImFub255bW91cyIsImlzcyI6Imh0dHBzOi8vc2VjdXJldG9rZW4uZ29vZ2xlLmNvbS9ydW5yZWFsbSIsImF1ZCI6InJ1bnJlYWxtIiwiYXV0aF90aW1lIjoxNzY0MTQzOTcwLCJ1c2VyX2lkIjoiVWVJMVV2NWpNa2VWR082emFpakJCUjFlcXF3MiIsInN1YiI6IlVlSTFVdjVqTWtlVkdPNnphaWpCQlIxZXFxdzIiLCJpYXQiOjE3NjQxNDM5NzIsImV4cCI6MTc2NDE0NzU3MiwiZmlyZWJhc2UiOnsiaWRlbnRpdGllcyI6e30sInNpZ25faW5fcHJvdmlkZXIiOiJhbm9ueW1vdXMifX0.Q22z2lkXE49digPu4cdaU6-EALKqi7GnAxQKN4_n-etSwNyRn2C0XruJttyeJLqSHEXj5VwfZBthl5EYuE1CHhdYOi7IgdPg5R5dhjq51SlJ2Q6FiE4smqLTjRWCUtlBlH7adzWldciK3ynvsuCWGe0i7H6Nutewx7BkMXNiCWkipEMF957CHqW4a54vNskDOaO5RDorKq7H1dn6-vp3HYyqKRhXoJCfECbFopCEaBmX-p-HV4uqcGOhYmLa9YIErISsCnRcbSxrG1Eq2NifkSZSsxRVVVBK_5_VeEvZWKUwbb5DFXlYCw8jwUq58F1ijsKpQvPW61-a8AM_71GSngw";

const RUN_ID = "pdUPkQgpSxtbUK503cuo";

async function testCreateFromRun() {
    const url = 'http://localhost:8080/territories/create-from-run';

    const body = {
        runId: RUN_ID
    };

    try {
        console.log(`Testing /territories/create-from-run with run ID: ${RUN_ID}\n`);
        console.log("This endpoint will:");
        console.log("1. Verify Firebase token");
        console.log("2. Fetch run data from Firestore");
        console.log("3. Extract path coordinates");
        console.log("4. Calculate area using PostGIS");
        console.log("5. Store territory in PostgreSQL\n");

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
            console.log("\n✅ SUCCESS: Complete data flow verified!");
            console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            console.log("Run ID:", data.runId);
            console.log("Territory ID:", data.territoryId);
            console.log("Path Points:", data.pathPoints);
            console.log("Area:", data.area_m2.toFixed(2), "sq meters");
            console.log("Area:", (data.area_m2 / 1000000).toFixed(4), "sq kilometers");
            console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            console.log("\n🎉 Data flow:");
            console.log("  Firebase (run data) → Node API → PostGIS (territory) ✓");
        } else {
            console.log("\n❌ FAILURE:", data.error);
        }

    } catch (error) {
        console.error("\n❌ Error executing test:", error.message);
    }
}

testCreateFromRun();
