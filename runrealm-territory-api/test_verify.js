const TOKEN = "eyJhbGciOiJSUzI1NiIsImtpZCI6IjQ1YTZjMGMyYjgwMDcxN2EzNGQ1Y2JiYmYzOWI4NGI2NzYxMjgyNjUiLCJ0eXAiOiJKV1QifQ.eyJwcm92aWRlcl9pZCI6ImFub255bW91cyIsImlzcyI6Imh0dHBzOi8vc2VjdXJldG9rZW4uZ29vZ2xlLmNvbS9ydW5yZWFsbSIsImF1ZCI6InJ1bnJlYWxtIiwiYXV0aF90aW1lIjoxNzY0MTQzOTcwLCJ1c2VyX2lkIjoiVWVJMVV2NWpNa2VWR082emFpakJCUjFlcXF3MiIsInN1YiI6IlVlSTFVdjVqTWtlVkdPNnphaWpCQlIxZXFxdzIiLCJpYXQiOjE3NjQxNDM5NzIsImV4cCI6MTc2NDE0NzU3MiwiZmlyZWJhc2UiOnsiaWRlbnRpdGllcyI6e30sInNpZ25faW5fcHJvdmlkZXIiOiJhbm9ueW1vdXMifX0.Q22z2lkXE49digPu4cdaU6-EALKqi7GnAxQKN4_n-etSwNyRn2C0XruJttyeJLqSHEXj5VwfZBthl5EYuE1CHhdYOi7IgdPg5R5dhjq51SlJ2Q6FiE4smqLTjRWCUtlBlH7adzWldciK3ynvsuCWGe0i7H6Nutewx7BkMXNiCWkipEMF957CHqW4a54vNskDOaO5RDorKq7H1dn6-vp3HYyqKRhXoJCfECbFopCEaBmX-p-HV4uqcGOhYmLa9YIErISsCnRcbSxrG1Eq2NifkSZSsxRVVVBK_5_VeEvZWKUwbb5DFXlYCw8jwUq58F1ijsKpQvPW61-a8AM_71GSngw";

async function test() {
    console.log("Testing /verify-token endpoint...\n");

    const response = await fetch('http://localhost:8080/verify-token', {
        method: 'POST',
        headers: {
            'Authorization': `Bearer ${TOKEN}`
        }
    });

    const data = await response.json();
    console.log("Status:", response.status);
    console.log("Response:", JSON.stringify(data, null, 2));
}

test();
