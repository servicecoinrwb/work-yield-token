
const provider = new ethers.providers.Web3Provider(window.ethereum);
let signer;
let contract;

const CONTRACT_ADDRESS = "0x97500Ac1B27931b0a36fe4713B6Af455F5308545";
const ABI = [
  "function buyTokens(uint256) external",
  "function redeemTokens(uint256) external",
  "function availableTokens() view returns (uint256)",
  "function totalReserveFund() view returns (uint256)",
  "function contractPaymentTokenBalance() view returns (uint256)",
  "function redemptionFeePercentage() view returns (uint256)",
  "function mintFromWorkOrder(uint256,string) external",
  "function cancelWorkOrder(uint256) external",
  "function withdrawFees() external",
  "function setRedemptionFee(uint256) external",
  "function workOrders(uint256) view returns (uint256 id,uint256 grossYield,uint256 reserveAmount,uint256 tokensIssued,bool isActive,bool isPaid,string description,uint256 createdAt)",
  "function nextWorkOrderId() view returns (uint256)"
];

async function connect() {
  await provider.send("eth_requestAccounts", []);
  signer = provider.getSigner();
  contract = new ethers.Contract(CONTRACT_ADDRESS, ABI, signer);
  await loadStats();
  await loadWorkOrders();
}

async function loadStats() {
  try {
    const [available, reserve, payment, fee] = await Promise.all([
      contract.availableTokens(),
      contract.totalReserveFund(),
      contract.contractPaymentTokenBalance(),
      contract.redemptionFeePercentage()
    ]);

    document.getElementById("availableTokens").innerText = ethers.utils.formatUnits(available, 18);
    document.getElementById("reserve").innerText = ethers.utils.formatUnits(reserve, 18);
    document.getElementById("paymentBalance").innerText = ethers.utils.formatUnits(payment, 18);
    document.getElementById("fee").innerText = fee.toString() + "%";
  } catch (error) {
    console.error("Stats error:", error);
  }
}

async function loadWorkOrders() {
  try {
    const table = document.getElementById("workOrdersTable");
    const count = await contract.nextWorkOrderId();
    table.innerHTML = `<tr><th>ID</th><th>Yield</th><th>Reserve</th><th>Tokens</th><th>Status</th><th>Description</th><th>Date</th></tr>`;
    for (let i = 0; i < count; i++) {
      const order = await contract.workOrders(i);
      const status = order.isPaid ? "✅ Paid" : (order.isActive ? "🟡 Active" : "❌ Cancelled");
      const row = `
        <tr>
          <td>${order.id}</td>
          <td>${ethers.utils.formatUnits(order.grossYield, 18)}</td>
          <td>${ethers.utils.formatUnits(order.reserveAmount, 18)}</td>
          <td>${ethers.utils.formatUnits(order.tokensIssued, 18)}</td>
          <td>${status}</td>
          <td>${order.description}</td>
          <td>${new Date(order.createdAt * 1000).toLocaleDateString()}</td>
        </tr>`;
      table.innerHTML += row;
    }
  } catch (error) {
    console.error("Load Work Orders error:", error);
  }
}

window.onload = connect;
