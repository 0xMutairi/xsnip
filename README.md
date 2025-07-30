#  XSnip Recon Tool

XSnip is a **Bash-based reconnaissance automation tool** built for **bug bounty hunters and red teamers**.  
It automates **subdomain enumeration, URL discovery, vulnerability scanning, and report generation**, making recon faster and more efficient.

---

##  Features
✅ **Subdomain Enumeration** – Uses Subfinder, Assetfinder, and more  
✅ **URL Discovery** – Extracts historical URLs from Wayback Machine and gau  
✅ **Vulnerability Scanning** – Integrated Nuclei & GF patterns for fast checks  
✅ **Port Scanning** – Nmap integration for open ports and service detection  
✅ **Automated Reports** – Generates markdown-based recon reports  

---

## 📦 Installation
```bash
git clone https://github.com/0xMutairi/XSnip.git
cd XSnip
chmod +x xsnip.sh
```

---

##  Usage
```bash
./xsnip.sh target.com
```

---

## 📊 Workflow
1. Subdomain enumeration → Passive + Active
2. URL collection → Gau + Waybackurls
3. Vulnerability scanning → Nuclei + GF patterns
4. Report generation in Markdown format

---

## 🛠️ Tech Stack
- **Bash**
- Nmap
- Nuclei
- Subfinder
- HTTPx
- GF patterns

---

##  Impact
XSnip has been used to **discover real-world vulnerabilities** in bug bounty programs and **streamline reconnaissance workflows** for penetration testing.

---

## 📜 License
MIT License – Free to use and modify.
