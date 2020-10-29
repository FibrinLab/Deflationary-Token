pragma solidity 0.6.2;

import "openzeppelin-solidity/contracts/GSN/Context.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/utils/Address.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";

contract SPAMToken is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 public deflationRate = 100; // 1 % of the transfer amount.

    uint256 public newAccountDeflationRate = 3; // 3 % of the current balance of the token holder.

    uint256 public constant NEW_ACCOUNT_DEFLATION_TIME = 5 days; // 5 days is the relaxation time for the non-zero token holder.

    // Start time at which 5 days cycle starts.
    uint256 public newAccountDeflationStartTime;

    // Timestamp at which new account balance burned with 3 % of the total balance.
    uint256 public nextNewAccountDeflationTimePeriod;

    // Mapping to keep track which account is new account (moved recently from the zero balance to non-zero balance).
    mapping(address => bool) public accountToBeDeducted;

    // Mapping to keep track of timestamp at which 3 % deflation applied for given investor.
    mapping(address => uint256) public deductedAfterTime;

    // Contains the list of token holders who are immune of any deflation.
    mapping(address => bool) public skippedAccountFromDeflation;

    uint256 private _totalSupply;

    string private _name = "SPAM Token";
    string private _symbol = "SPAM";
    uint8 private _decimals = 18;

    event AccountFromDeflationSkipped(address account);

    event AccountRemovedFromSkipDeflationList(address account);

    constructor (address account) public {
        require(account != address(0), "ERC20: Zero address not allowed");
        skippedAccountFromDeflation[account] = true;
        uint256 _amountToMint = 100000 * 10 ** 18;
        newAccountDeflationStartTime = now;
        nextNewAccountDeflationTimePeriod = now + NEW_ACCOUNT_DEFLATION_TIME;
        _mint(account, _amountToMint);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public virtual override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public virtual override view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public virtual override view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }
    
    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        burn(amount);
    }

    /**
     * @dev Used to add an account in the allowed list that will skip the deflation for them.
     * @param account Address for whom deflation is skipped.
     */
    function skipAccountFromDeflation(address account) external onlyOwner {
        require(account != address(0), "ERC20: Zero address not allowed");
        skippedAccountFromDeflation[account] = true;
        emit AccountFromDeflationSkipped(account);
    }

    /**
     * @dev Used to remove an account from the allowed list that will skip the deflation for them.
     * @param account Address for whom deflation is skipped.
     */
    function removeAccountFromSkipDeflationList(address account) external onlyOwner {
        require(account != address(0), "ERC20: Zero address not allowed");
        skippedAccountFromDeflation[account] = false;
        emit AccountRemovedFromSkipDeflationList(account);
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _applyNewAccountDeflation(sender, recipient);
        uint256 _remainingAmount = _applyRegularTransferDeflation(sender, amount);

        _balances[sender] = _balances[sender].sub(_remainingAmount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(_remainingAmount);
        emit Transfer(sender, recipient, _remainingAmount);
    }

    /**
     * @dev Internal function - It will burn the 3 % of the current holdings of the sender
     * only if the sender is moves from zero balance to non-zero balance in last deflation time period.
     */
    function _applyNewAccountDeflation(address sender, address receiver) internal {
        if (!skippedAccountFromDeflation[sender] && (accountToBeDeducted[sender] && now >= deductedAfterTime[sender])) {
            // Burn 3 % of transfer amount.
            uint256 _burnAmount = _balances[sender].mul(newAccountDeflationRate) / 100;
            _unsafeBurn(sender, _burnAmount);
            _removeNewAccountStatus(sender);
        }
        if (_balances[receiver] == 0 && !skippedAccountFromDeflation[receiver]) {
            if (now > nextNewAccountDeflationTimePeriod) {
                // calculate the next deflation timestamp.
                uint256 passedPeriods = (now - newAccountDeflationStartTime).div(NEW_ACCOUNT_DEFLATION_TIME);
                // Next period will always be one more than the passed periods length.
                nextNewAccountDeflationTimePeriod = newAccountDeflationStartTime.add((passedPeriods + 1) * NEW_ACCOUNT_DEFLATION_TIME);
            }
            // Provide new account status only if the current balance of receiver is zero.
            _provideNewAccountStatus(receiver, nextNewAccountDeflationTimePeriod);
        }
    }

    /**
     * @dev Purge the new account status for the given target account.
     */
    function _removeNewAccountStatus(address target) internal {
        delete accountToBeDeducted[target];
        delete deductedAfterTime[target];
    }

    /**
     * @dev Provide the new account status to the given target account.
     */
    function _provideNewAccountStatus(address target, uint256 time) internal {
        if (!accountToBeDeducted[target]) {
            accountToBeDeducted[target] = true;
            deductedAfterTime[target] = time;
        }
    }

    /**
     * @dev Burn 1 % of the sending amount.
     */
    function _applyRegularTransferDeflation(address sender, uint256 amount) internal returns (uint256 _remainingAmount){
        // Skipping `sender` to burn token it is exists in the skipping list.
        if (!skippedAccountFromDeflation[sender]) {
            // Burn 1 % of transfer amount.
            uint256 _burnAmount = amount / deflationRate;
            _remainingAmount = amount - _burnAmount;
            _unsafeBurn(sender, _burnAmount);
        } else {
            _remainingAmount = amount;
        }
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        _unsafeBurn(account, amount);
    }

    /**
     * @dev Unsafe version of the burn method.
     */
    function _unsafeBurn(address account, uint256 amount) internal  {
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }
}
