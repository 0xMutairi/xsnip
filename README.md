#  XSnip v3 

XSnip v3 is a **hyper-parallel reconnaissance pipeline** designed for **serious bug bounty hunters and red teamers**.  
It automates **subdomain enumeration, live host probing, URL & endpoint discovery, secret detection, nuclei scanning, and report generation** at scale.

---

## 🚀 Features
✅ **Hyper-parallel execution** with GNU Parallel  
✅ **Subdomain Enumeration** – Subfinder, Amass, DNSx  
✅ **Live Host Probing** – HTTPx with titles, tech detection, status codes  
✅ **Endpoint Discovery** – Gau, Wayback, Katana crawler, JS endpoint extraction  
✅ **Secret Hunting** – Git-hound, Trufflehog3 integration  
✅ **Vulnerability Scanning** – Nuclei (Critical/High findings prioritized)  
✅ **Reporting** – Generates a detailed Markdown report  
✅ **Optional Integrations** – Gowitness screenshots, FavUp favicon hashing, Slack webhook alerts  

---

## 📦 Installation
```bash
git clone https://github.com/0xMutairi/xsnip.git
cd xsnip
chmod +x xsnip.sh
```

---

##   Usage
```bash
./xsnip.sh <target.com> [options]

Options:
  -c, --config <file>   Custom YAML config (default: xsnip.yml)
  -o, --outdir <dir>    Output directory (default: xsnip-<target>-<timestamp>)
  --fast                Skip heavy modules (Amass, Katana, Gowitness)
  --update              Update to latest version
```

---

## 📊 Workflow
1️⃣ **Subdomain Enumeration** → Subfinder, Amass (if installed)  
2️⃣ **DNS Resolution** → DNSx filters valid domains  
3️⃣ **Live Host Probing** → HTTPx collects titles, status codes, technologies  
4️⃣ **URL & Endpoint Discovery** → Gau, Wayback, Katana crawler, JS endpoint parsing  
5️⃣ **Secret Detection** → Git-hound, Trufflehog3 (optional with GitHub token)  
6️⃣ **Vulnerability Scanning** → Nuclei with selected tags/severities  
7️⃣ **Screenshots & Favicons** → Gowitness & FavUp (optional)  
8️⃣ **Report Generation** → Markdown summary (`report.md`)  

---

## 🛠️ Tech Stack
- **Bash + GNU Parallel**
- Subfinder, Amass, DNSx
- HTTPx, Gau, Waybackurls
- Katana (optional)
- Git-hound, Trufflehog3
- Nuclei
- Gowitness (optional)

---

## 📜 Output
📁 **Report:** `report.md` (Markdown summary)  
📄 **Supporting Files:**  
- `subs_all.txt` – All discovered subdomains  
- `resolved.txt` – Valid DNS-resolved subdomains  
- `live.txt` – Live hosts from HTTPx  
- `endpoints.txt` – Extracted endpoints  
- `nuclei.txt` – Vulnerability scan results  

---

##   Impact
XSnip v3 **streamlines reconnaissance at scale**, enabling faster **attack surface mapping and vulnerability discovery** for bug bounty and red team engagements.

---

## 📜 License
MIT License – Free to use and modify.
