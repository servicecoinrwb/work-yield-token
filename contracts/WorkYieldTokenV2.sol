// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// File: @openzeppelin/contracts/utils/Context.sol
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol
abstract contract Ownable is Context {
    address private _owner;

    error OwnableUnauthorizedAccount(address account);
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol
abstract contract ReentrancyGuard {
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = NOT_ENTERED;
    }

    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/interfaces/draft-IERC6093.sol
interface IERC20Errors {
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);
    error ERC20InvalidSender(address sender);
    error ERC20InvalidReceiver(address receiver);
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);
    error ERC20InvalidApprover(address approver);
    error ERC20InvalidSpender(address spender);
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol
abstract contract ERC20 is Context, IERC20, IERC20Metadata, IERC20Errors {
    mapping(address account => uint256) private _balances;
    mapping(address account => mapping(address spender => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                _totalSupply -= value;
            }
        } else {
            unchecked {
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}


// File: WorkYieldTokenV2.sol
/**
 * @title WorkYieldToken V2
 * @dev This contract tokenizes future yield from work orders using a stablecoin (pUSD) for payments.
 * It includes secure fee handling and relies on an ERC-20 token for all financial operations.
 */
contract WorkYieldTokenV2 is ERC20, Ownable, ReentrancyGuard {
    // --- State Variables ---

    IERC20 public paymentToken; // The stablecoin used for payments (e.g., pUSD)
    uint256 public collectedFees; // Securely tracks fees for withdrawal

    uint256 public constant RESERVE_PERCENTAGE = 5; // 5% reserve
    uint256 public redemptionFeePercentage = 10; // 10% fee on redemption
    uint256 public totalReserveFund;
    uint256 public nextWorkOrderId = 1;

    mapping(uint256 => WorkOrder) public workOrders;

    struct WorkOrder {
        uint256 id;
        uint256 grossYield; // Denominated in the paymentToken
        uint256 reserveAmount;
        uint256 tokensIssued;
        bool isActive;
        bool isPaid;
        string description;
        uint256 createdAt;
    }

    // --- Events ---

    event WorkOrderMinted(uint256 workOrderId, uint256 yieldAmount, uint256 tokensIssued);
    event TokensRedeemed(address indexed holder, uint256 amount, uint256 feeCollected);
    event ReserveFunded(uint256 amount);
    event RedemptionFeeSet(uint256 newFeePercentage);

    // --- Constructor ---

    constructor(address initialOwner, address paymentTokenAddress)
        ERC20("WorkYield Token", "WYT")
        Ownable(initialOwner)
    {
        require(paymentTokenAddress != address(0), "Payment token cannot be zero address");
        paymentToken = IERC20(paymentTokenAddress);
    }

    // --- Core Functions ---

    /**
     * @dev Mints tokens against a new work order. Yield is denominated in the payment token.
     */
    function mintFromWorkOrder(uint256 grossYield, string memory description) external onlyOwner returns (uint256) {
        require(grossYield > 0, "Yield must be positive");

        uint256 workOrderId = nextWorkOrderId++;
        uint256 reserveAmount = (grossYield * RESERVE_PERCENTAGE) / 100;
        uint256 tokensToIssue = grossYield - reserveAmount;

        totalReserveFund += reserveAmount;

        workOrders[workOrderId] = WorkOrder({
            id: workOrderId,
            grossYield: grossYield,
            reserveAmount: reserveAmount,
            tokensIssued: tokensToIssue,
            isActive: true,
            isPaid: false,
            description: description,
            createdAt: block.timestamp
        });

        _mint(address(this), tokensToIssue);

        emit WorkOrderMinted(workOrderId, grossYield, tokensToIssue);
        emit ReserveFunded(reserveAmount);

        return workOrderId;
    }

    /**
     * @dev Allows users to buy WYT with the specified paymentToken (pUSD).
     * The user must approve this contract to spend their paymentTokens first.
     */
    function buyTokens(uint256 amount) external nonReentrant {
        require(balanceOf(address(this)) >= amount, "Insufficient tokens available in contract");

        // Pull paymentToken from user to this contract
        bool success = paymentToken.transferFrom(msg.sender, address(this), amount);
        require(success, "Payment token transfer failed.");

        // Transfer WYT from contract to user
        _transfer(address(this), msg.sender, amount);
    }

    /**
     * @dev Allows users to redeem their WYT for the paymentToken (pUSD), minus a fee.
     */
    function redeemTokens(uint256 amount) external nonReentrant {
        require(balanceOf(msg.sender) >= amount, "Insufficient WYT balance");

        uint256 fee = (amount * redemptionFeePercentage) / 100;
        uint256 redemptionAmount = amount - fee;

        require(paymentToken.balanceOf(address(this)) >= redemptionAmount, "Insufficient contract payment token balance");

        // Add the fee to the owner's withdrawable balance
        collectedFees += fee;

        // User transfers WYT to the contract, which then burns them
        _transfer(msg.sender, address(this), amount);
        _burn(address(this), amount);

        // Send the paymentToken (pUSD) to the user
        bool success = paymentToken.transfer(msg.sender, redemptionAmount);
        require(success, "Payment token redemption failed.");

        emit TokensRedeemed(msg.sender, amount, fee);
    }

    /**
     * @dev Allows the owner to fund the contract with paymentTokens from a completed work order.
     * The owner must approve this contract to spend their paymentTokens first.
     */
    function fundFromWorkOrderPayment(uint256 workOrderId, uint256 amount) external onlyOwner {
        require(workOrders[workOrderId].isActive, "Work order not active");
        require(!workOrders[workOrderId].isPaid, "Work order already paid");

        // Pull paymentTokens from the owner's wallet to fund the contract
        bool success = paymentToken.transferFrom(msg.sender, address(this), amount);
        require(success, "Funding transfer failed.");

        workOrders[workOrderId].isPaid = true;
    }


    // --- Admin and View Functions ---

    /**
     * @dev Emergency function to handle cancelled work orders.
     */
    function cancelWorkOrder(uint256 workOrderId) external onlyOwner {
        require(workOrders[workOrderId].isActive, "Work order not active");
        WorkOrder storage order = workOrders[workOrderId];
        order.isActive = false;
        // Note: Further logic may be required to handle token backing
    }

    /**
     * @dev Updates the redemption fee percentage.
     */
    function setRedemptionFee(uint256 newFeePercentage) external onlyOwner {
        require(newFeePercentage <= 20, "Fee cannot exceed 20%");
        redemptionFeePercentage = newFeePercentage;
        emit RedemptionFeeSet(newFeePercentage);
    }

    /**
     * @dev Securely allows the owner to withdraw only the fees that have been collected.
     */
    function withdrawFees() external onlyOwner {
        uint256 feesToWithdraw = collectedFees;
        require(feesToWithdraw > 0, "No fees to withdraw");

        collectedFees = 0; // Reset before transfer to prevent re-entrancy

        bool success = paymentToken.transfer(owner(), feesToWithdraw);
        require(success, "Fee withdrawal transfer failed.");
    }

    /**
     * @dev Gets the contract's balance of the paymentToken (pUSD).
     */
    function contractPaymentTokenBalance() external view returns (uint256) {
        return paymentToken.balanceOf(address(this));
    }

    /**
     * @dev Gets available WYT for purchase from the contract.
     */
    function availableTokens() external view returns (uint256) {
        return balanceOf(address(this));
    }
}