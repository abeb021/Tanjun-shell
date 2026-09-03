.pragma library

function score(query, text) {
    if (!query)
        return 0;
    const q = `${query}`.toLowerCase();
    const t = `${text}`.toLowerCase();
    let qi = 0;
    let streak = 0;
    let prev = -2;
    let total = 0;
    for (let ti = 0; ti < t.length && qi < q.length; ti++) {
        if (t.charAt(ti) !== q.charAt(qi))
            continue;
        let bonus = 1;
        if (ti === prev + 1) {
            streak += 1;
            bonus += streak * 3;
        } else {
            streak = 0;
        }
        const pc = ti > 0 ? t.charAt(ti - 1) : " ";
        if (pc === " " || pc === "·" || pc === "/" || pc === "-")
            bonus += 6;
        if (ti === 0)
            bonus += 8;
        total += bonus;
        prev = ti;
        qi += 1;
    }
    return qi === q.length ? total : -1;
}

function rank(query, items) {
    const out = [];
    if (!query || !items)
        return out;
    for (let i = 0; i < items.length; i++) {
        const it = items[i];
        const s = score(query, it.hay || it.title || "");
        if (s < 0)
            continue;
        out.push({
            title: it.title,
            sub: it.sub,
            page: it.page,
            face: it.face || "",
            kind: it.kind || "",
            name: it.name || "",
            score: s
        });
    }
    out.sort((a, b) => b.score - a.score);
    return out;
}
