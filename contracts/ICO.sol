pragma solidity ^0.5.7;

contract ERC20Interface {
    function transfer(address to, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function approve(address spender, uint tokens) public returns (bool success);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function totalSupply() public view returns (uint);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ERC20Token is ERC20Interface {
    string public name = 'My Token';
    string public symbol= 'TKN';
    uint8 public decimals = 18;
    uint public _totalSupply = 1000000;
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowed;
        
    function transfer(address to, uint value) public returns(bool) {
        require(balances[msg.sender] >= value, 'token balance too low');
        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        uint allowance = allowed[from][msg.sender];
        require(allowance >= value, 'allowance too low');
        require(balances[from] >= value, 'token balance too low');
        allowed[from][msg.sender] -= value;
        balances[from] -= value;
        balances[to] += value;
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint value) public returns(bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function allowance(address owner, address spender) public view returns(uint) {
        return allowed[owner][spender];
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }

    function totalSupply() public view returns (uint) {
      return _totalSupply;
    }
}

contract ICO is ERC20Token {
    struct Sale {
        address investor;
        uint quantity;
    }
    Sale[] public sales;
    mapping(address => bool) public investors;
    address public token;
    address public admin;
    uint public end;
    uint public price;
    uint public availableTokens;
    uint public minPurchase;
    uint public maxPurchase;
    bool public released;
    
    constructor()
        public {
        token = address(new ERC20Token());

        admin = msg.sender;
    }

    //I have added this function for the frontend
    function getSale(address _investor) external view returns(uint) {
      for(uint i = 0; i < sales.length; i++) {
        if(sales[i].investor == _investor) {
          return sales[i].quantity;
        }
      }
      return 0;
    }
    
    function start(
        uint duration,
        uint _price,
        uint _availableTokens,
        uint _minPurchase,
        uint _maxPurchase)
        external
        onlyAdmin() 
        icoNotActive() {
        require(duration > 0, 'duration should be > 0');
        uint totalSupply = ERC20Token(token).totalSupply();
        require(_availableTokens > 0 && _availableTokens <= totalSupply, 'totalSupply should be > 0 and <= totalSupply');
        require(_minPurchase > 0, '_minPurchase should > 0');
        require(_maxPurchase > 0 && _maxPurchase <= _availableTokens, '_maxPurchase should be > 0 and <= _availableTokens');
        end = duration + now; 
        price = _price;
        availableTokens = _availableTokens;
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
    }
    
    function whitelist(address investor)
        external
        onlyAdmin() {
        investors[investor] = true;    
    }
    
    function buy()
        payable
        external
        onlyInvestors()
        icoActive() {
        require(msg.value % price == 0, 'have to send a multiple of price');
        require(msg.value >= minPurchase && msg.value <= maxPurchase, 'have to send between minPurchase and maxPurchase');
        uint quantity = price * msg.value;
        require(quantity <= availableTokens, 'Not enough tokens left for sale');
        sales.push(Sale(
            msg.sender,
            quantity
        ));
        availableTokens -= quantity;
    }
    
    function release()
        external
        onlyAdmin()
        icoEnded()
        tokensNotReleased() {
        ERC20Token tokenInstance = ERC20Token(token);
        for(uint i = 0; i < sales.length; i++) {
            Sale storage sale = sales[i];
            tokenInstance.transfer(sale.investor, sale.quantity);
        }
        released = true;
    }
    
    function withdraw(
        address payable to,
        uint amount)
        external
        onlyAdmin()
        icoEnded()
        tokensReleased() {
        to.transfer(amount);    
    }
    
    modifier icoActive() {
        require(end > 0 && now < end && availableTokens > 0, "ICO must be active");
        _;
    }
    
    modifier icoNotActive() {
        require(end == 0, 'ICO should not be active');
        _;
    }
    
    modifier icoEnded() {
        require(end > 0 && (now >= end || availableTokens == 0), 'ICO must have ended');
        _;
    }
    
    modifier tokensNotReleased() {
        require(released == false, 'Tokens must NOT have been released');
        _;
    }
    
    modifier tokensReleased() {
        require(released == true, 'Tokens must have been released');
        _;
    }
    
    modifier onlyInvestors() {
        require(investors[msg.sender] == true, 'only investors');
        _;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin, 'only admin');
        _;
    }
    
}