// Variables used by Scriptable.
// These must be at the very top of the file. Do not edit.
// icon-color: gray; icon-glyph: magic;
// Hardcoded Colorado 14ers with their URLs
const fourteenersData = [
    { name: "Mount Elbert", url: "https://www.14ers.com/peaks/10001/mount-elbert" },
    { name: "Mount Massive", url: "https://www.14ers.com/peaks/10002/mount-massive" },
    { name: "Mount Harvard", url: "https://www.14ers.com/peaks/10003/mount-harvard" },
    { name: "Blanca Peak", url: "https://www.14ers.com/peaks/10004/blanca-peak" },
    { name: "La Plata Peak", url: "https://www.14ers.com/peaks/10005/la-plata-peak" },
    { name: "Uncompahgre Peak", url: "https://www.14ers.com/peaks/10006/uncompahgre-peak" },
    { name: "Crestone Peak", url: "https://www.14ers.com/peaks/10007/crestone-peak" },
    { name: "Mount Lincoln", url: "https://www.14ers.com/peaks/10008/mount-lincoln" },
    { name: "Grays Peak", url: "https://www.14ers.com/peaks/10009/grays-peak" },
    { name: "Mount Antero", url: "https://www.14ers.com/peaks/10010/mount-antero" },
    { name: "Torreys Peak", url: "https://www.14ers.com/peaks/10011/torreys-peak" },
    { name: "Castle Peak", url: "https://www.14ers.com/peaks/10012/castle-peak" },
    { name: "Quandary Peak", url: "https://www.14ers.com/peaks/10013/quandary-peak" },
    { name: "Mount Evans", url: "https://www.14ers.com/peaks/10014/mount-evans" },
    { name: "Longs Peak", url: "https://www.14ers.com/peaks/10015/longs-peak" },
    { name: "Mount Wilson", url: "https://www.14ers.com/peaks/10016/mount-wilson" },
    { name: "Mount Shavano", url: "https://www.14ers.com/peaks/10017/mount-shavano" },
    { name: "Mount Belford", url: "https://www.14ers.com/peaks/10018/mount-belford" },
    { name: "Crestone Needle", url: "https://www.14ers.com/peaks/10019/crestone-needle" },
    { name: "Mount Princeton", url: "https://www.14ers.com/peaks/10020/mount-princeton" },
    { name: "Mount Yale", url: "https://www.14ers.com/peaks/10021/mount-yale" },
    { name: "Mount Bross", url: "https://www.14ers.com/peaks/10022/mount-bross" },
    { name: "Kit Carson Peak", url: "https://www.14ers.com/peaks/10023/kit-carson-peak" },
    { name: "El Diente Peak", url: "https://www.14ers.com/peaks/10024/el-diente-peak" },
    { name: "Maroon Peak", url: "https://www.14ers.com/peaks/10025/maroon-peak" },
    { name: "Tabeguache Peak", url: "https://www.14ers.com/peaks/10026/tabeguache-peak" },
    { name: "Mount Oxford", url: "https://www.14ers.com/peaks/10027/mount-oxford" },
    { name: "Snowmass Mountain", url: "https://www.14ers.com/peaks/10028/snowmass-mountain" },
    { name: "Capitol Peak", url: "https://www.14ers.com/peaks/10029/capitol-peak" },
    { name: "Pikes Peak", url: "https://www.14ers.com/peaks/10030/pikes-peak" },
    { name: "Wetterhorn Peak", url: "https://www.14ers.com/peaks/10031/wetterhorn-peak" },
    { name: "San Luis Peak", url: "https://www.14ers.com/peaks/10032/san-luis-peak" },
    { name: "Mount Bierstadt", url: "https://www.14ers.com/peaks/10033/mount-bierstadt" },
    { name: "Sunlight Peak", url: "https://www.14ers.com/peaks/10034/sunlight-peak" },
    { name: "Windom Peak", url: "https://www.14ers.com/peaks/10035/windom-peak" },
    { name: "Challenger Point", url: "https://www.14ers.com/peaks/10036/challenger-point" },
    { name: "Mount Columbia", url: "https://www.14ers.com/peaks/10037/mount-columbia" },
    { name: "Missouri Mountain", url: "https://www.14ers.com/peaks/10038/missouri-mountain" },
    { name: "Huron Peak", url: "https://www.14ers.com/peaks/10039/huron-peak" },
    { name: "Handies Peak", url: "https://www.14ers.com/peaks/10040/handies-peak" },
    { name: "Culebra Peak", url: "https://www.14ers.com/peaks/10041/culebra-peak" },
    { name: "Ellingwood Point", url: "https://www.14ers.com/peaks/10042/ellingwood-point" },
    { name: "Mount Lindsey", url: "https://www.14ers.com/peaks/10043/mount-lindsey" },
    { name: "Little Bear Peak", url: "https://www.14ers.com/peaks/10044/little-bear-peak" },
];

// Fetch inputs from Shortcut
async function getInputs() {
    console.log("Fetching inputs from Shortcut...");
    if (args.shortcutParameter && typeof args.shortcutParameter === "object") {
        const { apiKey, mountainName } = args.shortcutParameter;
        if (!apiKey || !mountainName) {
            throw new Error("Missing API key or mountain name.");
        }
        console.log("Inputs received:", { apiKey, mountainName });
        return { apiKey, mountainName };
    } else {
        throw new Error("Invalid input provided by the Shortcut.");
    }
}

// Query ChatGPT API for mountain details
async function fetchMountainDetailsFromChatGPT(apiKey, mountainName) {
    const prompt = `
Provide the following details for the specified mountain:

1. Mountain Name (exactly as it is commonly used, with proper capitalization).
2. Height (in meters and feet).
3. Rough Location.
4. Indicate if it is a Colorado Fourteener.

Output the details in this exact format:

Name: [Mountain Name]  
Height: [Height in meters] m ([Height in feet] ft)  
Location: [Rough Location]  
IsFourteener: [Yes/No]

Do not include any additional text or explanation.
`;

    const query = `Mountain: ${mountainName}\n\n${prompt}`;
    const url = "https://api.openai.com/v1/chat/completions";
    const payload = {
        model: "gpt-3.5-turbo",
        messages: [{ role: "user", content: query }],
        max_tokens: 150,
    };

    const req = new Request(url);
    req.method = "POST";
    req.headers = {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiKey}`,
    };
    req.body = JSON.stringify(payload);

    try {
        const response = await req.loadJSON();
        const message = response.choices[0]?.message?.content?.trim();
        if (!message) {
            throw new Error("No response from ChatGPT.");
        }

        const detailsRegex = /Name: (.*?)\s+Height: (.*?)\s+Location: (.*?)\s+IsFourteener: (Yes|No)/s;
        const match = detailsRegex.exec(message);
        if (!match) {
            throw new Error("Failed to parse mountain details.");
        }

        const name = match[1].trim();
        const height = match[2].trim();
        const location = match[3].trim();
        const isFourteener = match[4].trim() === "Yes";

        return { name, height, location, isFourteener };
    } catch (error) {
        return { error: error.message };
    }
}

// Check if the mountain is a Fourteener and get its link
function getFourteenerLink(mountainName) {
    const normalizedInput = mountainName.toLowerCase().trim();
    for (const fourteener of fourteenersData) {
        const normalizedFourteener = fourteener.name.toLowerCase().trim();
        if (normalizedInput === normalizedFourteener) {
            return { isFourteener: true, url: fourteener.url };
        }
    }
    return { isFourteener: false, url: `https://www.google.com/search?q=${encodeURIComponent(mountainName)}` };
}

// Main script logic
(async () => {
    try {
        const { apiKey, mountainName } = await getInputs();
        const mountainDetails = await fetchMountainDetailsFromChatGPT(apiKey, mountainName);

        if (mountainDetails.error) {
            Script.setShortcutOutput({ error: mountainDetails.error });
            Script.complete();
            return;
        }

        // Validate against the hardcoded Fourteener list for consistent links
        const { isFourteener, url } = getFourteenerLink(mountainDetails.name);

        // Final output
        const output = {
            name: mountainDetails.name,
            elevation: mountainDetails.height,
            notes: mountainDetails.location,
            url: url,
            isFourteener: mountainDetails.isFourteener || isFourteener,
        };
        console.log("Final Output:", output);
        Script.setShortcutOutput(output);
    } catch (error) {
        Script.setShortcutOutput({ error: error.message });
    }
    Script.complete();
})();