// script.js for WorkYieldTokenV2

let provider, signer, contract;
const CONTRACT_ADDRESS = "0x97500Ac1B27931b0a36fe4713B6Af455F5308545";
const ABI = [
  "function buy(uint256 amount) external",
  "function redeem(uint256 amount) external",
  "function getAvailableTokens() view returns (uint256)",
  "function getReserveBalance() view returns (uint256)",
  "function getPaymentTokenBalance() view returns (uint256)",
  "function redemptionFee() view returns (uint256)",
  "function mintWorkOrder(uint256 amount, string calldata description, string calldata model, string calldata serial, string calldata tonnage) external",
  "function getWorkOrders() view returns ((uint256 id, string description, string model, string serial, string tonnage, uint256 yieldAmount, bool paid)[])",
  "function cancelWorkOrder(uint256 id) external",
  "function withdrawFees() external",
  "function setRedemptionFee(uint256 newFee) external"
];

async function connect() {
  provider = new ethers.providers.Web3Provider(window.ethereum);
  await provider.send("eth_requestAccounts", []);
  signer = provider.getSigner();
  contract = new ethers.Contract(CONTRACT_ADDRESS, ABI, signer);
  loadStats();
  checkOwner();
  loadWorkOrders();
}

async function loadStats() {
  const [available, reserve, payment, fee] = await Promise.all([
    contract.getAvailableTokens(),
    contract.getReserveBalance(),
    contract.getPaymentTokenBalance(),
    contract.redemptionFee()
  ]);
  document.getElementById("availableTokens").innerText = ethers.utils.formatUnits(available, 18);
  document.getElementById("totalReserve").innerText = ethers.utils.formatUnits(reserve, 18);
  document.getElementById("paymentBalance").innerText = ethers.utils.formatUnits(payment, 18);
  document.getElementById("redemptionFee").innerText = fee + "%";
}

async function checkOwner() {
  const address = await signer.getAddress();
  const owner = await contract.owner?.();
  if (address.toLowerCase() === owner?.toLowerCase()) {
    document.getElementById("adminPanel").classList.remove("hidden");
  }
}

async function buyWYT() {
  const amount = ethers.utils.parseUnits(document.getElementById("buyAmount").value, 18);
  const tx = await contract.buy(amount);
  await tx.wait();
  loadStats();
}

async function redeemWYT() {
  const amount = ethers.utils.parseUnits(document.getElementById("redeemAmount").value, 18);
  const tx = await contract.redeem(amount);
  await tx.wait();
  loadStats();
}

function setBuyMax() {
  document.getElementById("buyAmount").value = "10.00";
}
function setRedeemMax() {
  document.getElementById("redeemAmount").value = "10.00";
}

async function mintWorkOrder() {
  const amount = ethers.utils.parseUnits(document.getElementById("mintYield").value, 18);
  const desc = document.getElementById("mintDesc").value;
  const model = document.getElementById("mintModel").value;
  const serial = document.getElementById("mintSerial").value;
  const tonnage = document.getElementById("mintTonnage").value;
  const tx = await contract.mintWorkOrder(amount, desc, model, serial, tonnage);
  await tx.wait();
  loadWorkOrders();
  loadStats();
}

async function loadWorkOrders() {
  const orders = await contract.getWorkOrders();
  const table = document.getElementById("workTable");
  const search = document.getElementById("searchField").value.toLowerCase();
  const onlyUnpaid = document.getElementById("filterUnpaid").checked;
  table.innerHTML = "";

  let totalYield = 0;
  let paidYield = 0;

  orders.forEach((o) => {
    if (onlyUnpaid && o.paid) return;
    if (search && !(o.model.toLowerCase().includes(search) || o.serial.toLowerCase().includes(search))) return;

    const row = document.createElement("tr");
    row.className = "clickable-row";
    row.innerHTML = `
      <td>${o.id}</td>
      <td>${o.description}</td>
      <td>${o.model}</td>
      <td>${o.serial}</td>
      <td>${o.tonnage}</td>
      <td>${ethers.utils.formatUnits(o.yieldAmount, 18)}</td>
      <td>${o.paid ? '✅' : '❌'}</td>
      <td><button onclick="fundWorkOrder(${o.id})">Fund Now</button></td>
    `;
    table.appendChild(row);

    totalYield += parseFloat(ethers.utils.formatUnits(o.yieldAmount, 18));
    if (o.paid) paidYield += parseFloat(ethers.utils.formatUnits(o.yieldAmount, 18));
  });
  document.getElementById("totalYield").innerText = totalYield.toFixed(2);
  document.getElementById("percentPaid").innerText = totalYield ? ((paidYield / totalYield) * 100).toFixed(1) + "%" : "0%";
}

function exportCSV() {
  let rows = Array.from(document.querySelectorAll("#workTable tr")).map(row =>
    Array.from(row.children).map(cell => cell.innerText)
  );
  let csv = "ID,Description,Model,Serial,Tonnage,Yield,Paid\n" + rows.map(r => r.join(",")).join("\n");
  let blob = new Blob([csv], { type: 'text/csv' });
  let url = URL.createObjectURL(blob);
  let a = document.createElement('a');
  a.href = url;
  a.download = 'work-orders.csv';
  a.click();
  URL.revokeObjectURL(url);
}

async function withdrawFees() {
  const tx = await contract.withdrawFees();
  await tx.wait();
  loadStats();
}

async function setFee() {
  const fee = document.getElementById("newFee").value;
  const tx = await contract.setRedemptionFee(fee);
  await tx.wait();
  loadStats();
}

async function cancelWorkOrder() {
  const id = document.getElementById("cancelId").value;
  const tx = await contract.cancelWorkOrder(id);
  await tx.wait();
  loadWorkOrders();
}

function generatePDF() {
  const { jsPDF } = window.jspdf;
  const doc = new jsPDF();
  doc.text("Work Order Summary", 20, 20);
  let y = 40;
  document.querySelectorAll("#workTable tr").forEach(row => {
    let line = Array.from(row.children).map(cell => cell.innerText).join(" | ");
    doc.text(line, 10, y);
    y += 10;
  });
  doc.save("work-orders.pdf");
}

function fundWorkOrder(id) {
  alert("Funding logic here for Work Order #" + id);
}
