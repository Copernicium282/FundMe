import { ethers } from "./ethers-6.7.esm.min.js"
import { abi, contractAddress } from "./constants.js"

// UI DOM References
const connectButton = document.getElementById("connectButton")
const withdrawButton = document.getElementById("withdrawButton")
const fundButton = document.getElementById("fundButton")
const balanceDisplay = document.getElementById("balanceDisplay")
const totalFundedVal = document.getElementById("totalFundedVal")
const ethAmountInput = document.getElementById("ethAmount")

// Active Contract Configuration (Defaults to hardcoded constants)
let activeContractAddress = contractAddress
let activeAbi = abi

// Event Listeners
connectButton.onclick = connect
withdrawButton.onclick = withdraw
fundButton.onclick = fund

// Register MetaMask System Event Listeners to solve network/account alignment instantly
if (typeof window.ethereum !== "undefined") {
    window.ethereum.on("accountsChanged", async (accounts) => {
        await handleWalletState(accounts)
        await updateBalance()
    })
    window.ethereum.on("chainChanged", () => {
        // Automatically reloads the page to adapt to the new blockchain environment
        window.location.reload()
    })
}

// Initialize on page load
window.addEventListener("load", async () => {
    // Dynamic metadata discovery phase
    await loadContractMetadata()
    await updateBalance()
    
    if (typeof window.ethereum !== "undefined" && window.ethereum.selectedAddress) {
        await handleWalletState([window.ethereum.selectedAddress])
    }
})

// Helper to display elegant toast notifications
function showNotification(title, message, duration = 4000) {
    const toast = document.getElementById("toastAlert")
    const titleEl = document.getElementById("toastTitle")
    const msgEl = document.getElementById("toastMessage")
    
    titleEl.innerText = title
    msgEl.innerText = message
    toast.classList.add("active")
    
    setTimeout(() => {
        toast.classList.remove("active")
    }, duration)
}

// Dynamically discover ABI and Deployed Addresses based on connected network (Chain ID)
async function loadContractMetadata() {
    if (typeof window.ethereum !== "undefined") {
        try {
            const provider = new ethers.BrowserProvider(window.ethereum)
            const network = await provider.getNetwork()
            const chainId = network.chainId.toString()
            
            // 1. Dynamic ABI Discovery: Fetch compile artifact directly from out/
            try {
                const abiResponse = await fetch("../out/FundMe.sol/FundMe.json")
                if (abiResponse.ok) {
                    const abiData = await abiResponse.json()
                    activeAbi = abiData.abi
                    console.log("Successfully resolved and loaded ABI from compiled out/ directory.")
                }
            } catch (e) {
                console.log("Note: Could not fetch local out/ artifacts, utilizing hardcoded ABI.")
            }

            // 2. Dynamic Address Discovery: Fetch deploy logs matching MetaMask chain ID from broadcast/
            try {
                const broadcastResponse = await fetch(`../broadcast/DeployFundMe.s.sol/${chainId}/run-latest.json`)
                if (broadcastResponse.ok) {
                    const broadcastData = await broadcastResponse.json()
                    // Find the contract deployment (CREATE action)
                    const deployTx = broadcastData.transactions.find(
                        tx => tx.transactionType === "CREATE" && tx.contractName === "FundMe"
                    )
                    if (deployTx && deployTx.contractAddress) {
                        activeContractAddress = deployTx.contractAddress
                        console.log(`Successfully resolved deployed address for chain ${chainId}: ${activeContractAddress}`)
                    }
                }
            } catch (e) {
                console.log(`Note: No broadcast file found for chain ${chainId}, utilizing default fallback address.`)
            }
        } catch (error) {
            console.error("Fallback phase initiated due to provider metadata loading error.", error)
        }
    }
}

// Fetch and update contract balance metrics in the UI
async function updateBalance() {
    if (typeof window.ethereum !== "undefined") {
        const provider = new ethers.BrowserProvider(window.ethereum)
        try {
            const balance = await provider.getBalance(activeContractAddress)
            const formatted = parseFloat(ethers.formatEther(balance)).toFixed(4)
            balanceDisplay.innerText = formatted
            totalFundedVal.innerText = `${formatted} ETH`
        } catch (error) {
            console.error("Balance fetch failed", error)
        }
    }
}

// Coordinate active wallet status, button text, and owner panel authorizations
async function handleWalletState(accounts) {
    if (accounts.length > 0) {
        const activeAddress = accounts[0]
        const shortAddress = activeAddress.substring(0, 6) + "..." + activeAddress.substring(38)
        connectButton.innerText = shortAddress
        connectButton.style.background = "rgba(255, 255, 255, 0.05)"
        connectButton.style.color = "#ffffff"
        connectButton.style.border = "1px solid rgba(255, 255, 255, 0.15)"
        connectButton.style.boxShadow = "none"

        // Dynamically query the owner of the contract
        const provider = new ethers.BrowserProvider(window.ethereum)
        const contract = new ethers.Contract(activeContractAddress, activeAbi, provider)
        try {
            const owner = await contract.getOwner()
            if (owner.toLowerCase() === activeAddress.toLowerCase()) {
                withdrawButton.disabled = false
                showNotification("Authorized Owner", "Withdrawal dashboard is active.")
            } else {
                withdrawButton.disabled = true
                showNotification("Account Connected", "Successfully authorized wallet access.")
            }
        } catch (e) {
            console.error("Failed to query owner, keeping withdraw disabled", e)
        }
    }
}

// Initiate wallet connection requests
async function connect() {
    if (typeof window.ethereum !== "undefined") {
        try {
            showNotification("Connecting", "Requesting wallet authorization...")
            const accounts = await ethereum.request({ method: "eth_requestAccounts" })
            await handleWalletState(accounts)
            await updateBalance()
        } catch (error) {
            showNotification("Connection Rejected", "The user denied account access.")
            console.error(error)
        }
    } else {
        showNotification("Provider Missing", "MetaMask must be installed to interact.")
    }
}

// Perform contract funding
async function fund() {
    const ethAmount = ethAmountInput.value
    if (!ethAmount || parseFloat(ethAmount) <= 0) {
        showNotification("Invalid Amount", "Please input a positive ETH deposit amount.")
        return
    }

    if (typeof window.ethereum !== "undefined") {
        showNotification("Initializing", `Submitting deposit of ${ethAmount} ETH...`)
        const provider = new ethers.BrowserProvider(window.ethereum)
        await provider.send('eth_requestAccounts', [])
        const signer = await provider.getSigner()
        const contract = new ethers.Contract(activeContractAddress, activeAbi, signer)
        
        try {
            fundButton.disabled = true
            const txResponse = await contract.fund({
                value: ethers.parseEther(ethAmount),
            })
            showNotification("Pending", "Transaction broadcasted. Awaiting confirmation...")
            await txResponse.wait(1)
            showNotification("Confirmed", "Deposit successfully registered on-chain!")
            ethAmountInput.value = ""
            await updateBalance()
        } catch (error) {
            showNotification("Failed", "Transaction was rejected or crashed.")
            console.error(error)
        } finally {
            fundButton.disabled = false
        }
    } else {
        showNotification("Provider Missing", "MetaMask is required to fund.")
    }
}

// Perform contract withdrawals (dynamically falling back between cheaperWithdraw and withdraw)
async function withdraw() {
    if (typeof window.ethereum !== "undefined") {
        showNotification("Initializing", "Broadcasting owner withdrawal...")
        const provider = new ethers.BrowserProvider(window.ethereum)
        await provider.send('eth_requestAccounts', [])
        const signer = await provider.getSigner()
        const contract = new ethers.Contract(activeContractAddress, activeAbi, signer)
        
        try {
            withdrawButton.disabled = true
            let txResponse
            
            // Check if cheaperWithdraw exists in contract, otherwise fall back to withdraw
            if (typeof contract.cheaperWithdraw === "function") {
                console.log("Calling cheaperWithdraw...")
                txResponse = await contract.cheaperWithdraw()
            } else {
                console.log("Calling withdraw...")
                txResponse = await contract.withdraw()
            }
            
            showNotification("Pending", "Withdrawal processing. Awaiting block confirmation...")
            await txResponse.wait(1)
            showNotification("Confirmed", "All funds successfully withdrawn from the contract!")
            await updateBalance()
        } catch (error) {
            showNotification("Failed", "Withdrawal transaction failed.")
            console.error(error)
        } finally {
            // Re-verify if connected user is owner to maintain button state
            const accounts = await ethereum.request({ method: "eth_accounts" })
            if (accounts.length > 0) {
                const owner = await contract.getOwner()
                if (owner.toLowerCase() === accounts[0].toLowerCase()) {
                    withdrawButton.disabled = false
                }
            }
        }
    } else {
        showNotification("Provider Missing", "MetaMask is required to withdraw.")
    }
}
