pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Factory.sol";

contract NimbusCoin is Initializable, ERC20Upgradeable, OwnableUpgradeable {
    uint8 private _decimals;
    uint256 private _cap;
    IUniswapV2Router02 private _uniswapRouter;
    IUniswapV2Factory private _uniswapFactory;
    address private _uniswapPair;

    event LiquidityAdded(uint256 tokensSwapped, uint256 ethReceived);

    function initialize() initializer public {
        __ERC20_init("NimbusCoin", "NIM");
        __Ownable_init();

        _decimals = 18;
        _cap = 1_000_000_000 ether;

        _mint(msg.sender, 100_000_000 ether);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    function setUniswapRouter(address routerAddress) public onlyOwner {
        _uniswapRouter = IUniswapV2Router02(routerAddress);
    }

    function setUniswapFactory(address factoryAddress) public onlyOwner {
        _uniswapFactory = IUniswapV2Factory(factoryAddress);
    }

    function createUniswapPair() public onlyOwner {
        require(_uniswapRouter != address(0), "Uniswap router not set");
        require(_uniswapFactory != address(0), "Uniswap factory not set");
        require(_uniswapPair == address(0), "Uniswap pair already created");

        _uniswapPair = _uniswapFactory.createPair(address(this), _uniswapRouter.WETH());
    }

    function addLiquidity() public onlyOwner {
        require(_uniswapPair != address(0), "Uniswap pair not created");
        require(balanceOf(address(this)) > 0, "Not enough tokens in contract");

        uint256 tokenAmount = balanceOf(address(this));
        uint256 ethAmount = address(this).balance;

        _approve(address(this), address(_uniswapRouter), tokenAmount);

        _uniswapRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            tokenAmount,
            ethAmount,
            address(this),
            block.timestamp + 600
        );

        emit LiquidityAdded(tokenAmount, ethAmount);
    }

    function withdrawTokens(address to, uint256 amount) public onlyOwner {
        require(to != address(0), "Invalid address");
        require(amount > 0, "Invalid amount");
        require(amount <= balanceOf(address(this)), "Not enough tokens in contract");

        _transfer(address(this), to, amount);
    }

    function withdrawEth(address payable to, uint256 amount) public onlyOwner {
    require(to != address(0), "Invalid recipient address");
    require(amount <= address(this).balance, "Insufficient balance");
    to.transfer(amount);
    emit WithdrawETH(to, amount);
   }
   
       function burn(uint256 amount) external {
        require(amount <= balances[msg.sender], "insufficient balance");
        balances[msg.sender] = balances[msg.sender].sub(amount);
        totalSupply = totalSupply.sub(amount);
        emit Transfer(msg.sender, address(0), amount);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        require(amount <= _allowances[sender][msg.sender], "insufficient allowance");
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "approve from zero address");
        require(spender != address(0), "approve to zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "transfer from zero address");
        require(recipient != address(0), "transfer to zero address");
        require(amount <= balances[sender], "insufficient balance");

        balances[sender] = balances[sender].sub(amount);
        balances[recipient] = balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "mint to zero address");

        totalSupply = totalSupply.add(amount);
        balances[account] = balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
}
