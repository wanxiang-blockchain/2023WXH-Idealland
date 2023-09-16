pragma solidity ^0.4.19;

contract IDCard {
    //contract owner & init vars
    address public owner;
    
    //prestige value
    mapping(uint => uint) public PRESTIGE;
    
    //aboutme or profile info length limit
    uint public lengthLimit = 200;

    //register fee
    mapping(uint => uint) public FEE;

    //card structure
    struct card {
        bytes24 name;
        address addr;
        string profile;
        string aboutme;
        uint prestige;
        uint level;
        bool active;
        bool used;
        uint index;
    }

    //user wallet
    mapping(address => uint) public wallet;

    //ID name => personal info
    mapping(bytes24 => card) public info;
    mapping(address => bytes24) public IDs;
    mapping(address => bool) public usedAddr;
    
    //relationships
    struct relationStatus {
        bool followed;
        bool active; // if unfollowed it's false
    }
    
    mapping(bytes24 => mapping(bytes24 => relationStatus)) public rStatus;
    
    mapping(bytes24 => bytes24[]) public follow;
    mapping(bytes24 => uint) public follow_count;
    mapping(bytes24 => uint) public follow_count_total;
    mapping(bytes24 => bytes24[]) public followed;
    mapping(bytes24 => uint) public followed_count;
    mapping(bytes24 => uint) public followed_count_total;

    //comment structure
    struct comment {
        bytes24 from;
        string content;
        uint time;
    }

    //ID name => comments
    mapping(bytes24 => comment[]) public comments;
    mapping(bytes24 => uint) public comments_count;

    //moments structure
    struct moment {
        string content;
        uint time;
    }

    //ID name => moments
    mapping(bytes24 => moment[]) public moments;
    mapping(bytes24 => uint) public moment_count;

    //articles structure
    struct article {
        bytes32 title;
        string content;
        uint time;
        bool exist;
    }

    //ID name => articles
    mapping(bytes24 => article[]) public articles;
    mapping(bytes24 => uint) public article_count;
    
    // comments for moments
    mapping(bytes24 => mapping(uint => comment[])) public m_comments;
    mapping(bytes24 => mapping(uint => uint)) public m_comments_count;
    
    //AUCTION STRUCTURE
    //golden card left
    uint public goldStore = 999;
    
    bytes24 public highestBidder;
    uint public biddingPrice;
    uint public startTime;
    uint public biddingTime = 86400;


    //GOLDEN ID SPACE
    //golden ids list
    struct gold_record{
        bytes24 name;
        uint price;
        uint time;
        bool for_sell;
        uint price_for_sell;
    }
    mapping(uint => gold_record) public goldenList;
    //gold_record[] public goldenList;
    uint public gold_count;

    //modifiers
    modifier silverFee(uint amount) { require(amount == FEE[2] && goldStore!=0); _; }
    modifier copperFee(uint amount) { require(amount == FEE[3]); _; }
    modifier nameFree(bytes24 _name) { require(info[_name].used==false && _name!=""); _; } // ID name not used yet
    modifier nameUsed(bytes24 _name) { require(info[_name].used==true); _; } // ID name used
    modifier addressFree(address _addr) { require(usedAddr[_addr]==false); _; } // user not registered yet
    modifier lengthLim(string _content) { require(bytes(_content).length<=lengthLimit); _; } // basic length limit
    modifier isCopper(address _address) { require(info[IDs[_address]].level==3 && info[IDs[_address]].active==true); _; } // confirm active copper user
    modifier isSilver(address _address) { require(info[IDs[_address]].level==2 && info[IDs[_address]].active==true); _; } // confirm active silver user
    modifier isGold(address _address) { require(info[IDs[_address]].level==1 && info[IDs[_address]].active==true); _; } // confirm active gold user
    modifier canProfile(address _address) { require(info[IDs[_address]].level<3 && info[IDs[_address]].active==true); _; } // level highter than copper
    modifier activeUser(bytes24 _name) { require(info[_name].active==true); _; } // judge if a user is active
    modifier isOwner(address _address) { require(_address==owner); _; } // check if user is contract owner
    modifier articleExist(bytes24 _name, uint _number) { require(articles[_name][_number].exist==true); _; } // make sure article exist
    modifier successBid(uint _price) { require(goldStore!=0 && _price>=FEE[1]); _; }
    modifier forsell(uint target,uint value) { require(goldenList[target].for_sell==true && goldenList[target].price_for_sell==value); _; }
    modifier notGold(address _address) { require(info[IDs[_address]].level!=1 && IDs[_address]!=highestBidder); _; }


    //constructor
    constructor() public {
        owner = msg.sender;
        //set prestige for each ID style
        PRESTIGE[1] = 1000;
        PRESTIGE[2] = 10;
        PRESTIGE[3] = 1;
        //set ID price
        FEE[1] = 10000000000000000000;
        FEE[2] = 100000000000000000;
        FEE[3] = 10000000000000000;
        
        info["IDCard"] = card({
            name : "IDCard",
            addr : owner,
            profile : "",
            aboutme : "Creator of the IDCard",
            prestige : PRESTIGE[1],
            level : 1,
            active : true,
            used : true,
            index : 0
        });
        
        IDs[owner] = "IDCard";
        usedAddr[owner] = true;
        
        goldenList[0] = gold_record({
                name : "IDCard",
                price : 0,
                time : now,
                for_sell : false,
                price_for_sell : 0
            });
    }

    // silver card registration
    function silverRegister(bytes24 IDname, string about, string _profile) public payable 
    silverFee(msg.value)
    nameFree(IDname)
    addressFree(msg.sender)
    lengthLim(about)
    lengthLim(_profile){
        info[IDname] = card({
            name : IDname,
            addr : msg.sender,
            profile : _profile,
            aboutme : about,
            prestige : PRESTIGE[2],
            level : 2,
            active : true,
            used : true,
            index : 0
        });
        IDs[msg.sender] = IDname;
        usedAddr[msg.sender] = true;
        wallet[owner] += msg.value;
    }

    //copper card registration
    function copperRegister(bytes24 IDname, string about) public payable
    copperFee(msg.value)
    nameFree(IDname)
    addressFree(msg.sender)
    lengthLim(about){
        info[IDname] = card({
            name : IDname,
            addr : msg.sender,
            profile : "",
            aboutme : about,
            prestige : PRESTIGE[3],
            level : 3,
            active : true,
            used : true,
            index : 0
        });
        IDs[msg.sender] = IDname;
        usedAddr[msg.sender] = true;
        wallet[owner] += msg.value;
    }

    //copper card become silver
    function beSilver(string _profile) public payable
    isCopper(msg.sender)
    silverFee(msg.value)
    lengthLim(_profile){
        info[IDs[msg.sender]].level = 2;
        info[IDs[msg.sender]].profile = _profile;
        info[IDs[msg.sender]].prestige += 9;
        wallet[owner] += msg.value;
    }
    
    //follow a user;
    function fooollow(bytes24 aim) public
    activeUser(IDs[msg.sender])
    activeUser(aim){
        
        if(rStatus[IDs[msg.sender]][aim].followed==false){
            rStatus[IDs[msg.sender]][aim].followed = true;
            rStatus[IDs[msg.sender]][aim].active = true;
            follow[IDs[msg.sender]].push(aim);
            follow_count[IDs[msg.sender]] += 1;
            follow_count_total[IDs[msg.sender]] += 1;
            followed[aim].push(IDs[msg.sender]);
            followed_count[aim] += 1;
            followed_count_total[aim] += 1;
            info[aim].prestige += PRESTIGE[info[IDs[msg.sender]].level];
        }else if(rStatus[IDs[msg.sender]][aim].followed==true && rStatus[IDs[msg.sender]][aim].active==false){
            rStatus[IDs[msg.sender]][aim].active = true;
            follow_count[IDs[msg.sender]] += 1;
            followed_count[aim] += 1;
            //info[aim].prestige += PRESTIGE[info[IDs[msg.sender]].level];
        }
    }
    
    //unfollow a user
    function unfooollow(bytes24 aim) public
    activeUser(IDs[msg.sender])
    nameUsed(aim){
        if(rStatus[IDs[msg.sender]][aim].followed==true && rStatus[IDs[msg.sender]][aim].active==true){
            rStatus[IDs[msg.sender]][aim].active = false;
            follow_count[IDs[msg.sender]] -= 1;
            followed_count[aim] -= 1;
        }
    }
    
    //comment someone
    function cooomment(bytes24 aim, string _content) public
    activeUser(IDs[msg.sender])
    nameUsed(aim)
    lengthLim(_content){
        comments[aim].push(comment({
            from : IDs[msg.sender],
            content : _content,
            time : now
        }));
        comments_count[aim] += 1;
    }
    
    //comment moment
    function comment_moment(bytes24 aim, uint num, string _content) public
    activeUser(IDs[msg.sender])
    nameUsed(aim)
    lengthLim(_content){
        require(num<moment_count[aim]);
        m_comments[aim][num].push(comment({
            from : IDs[msg.sender],
            content : _content,
            time : now
        }));
        m_comments_count[aim][num] += 1;
    }
    
    //share a moment
    function moooment(string _content) public
    activeUser(IDs[msg.sender])
    lengthLim(_content){
        moments[IDs[msg.sender]].push(moment({
            content : _content,
            time : now
        }));
        moment_count[IDs[msg.sender]] += 1;
    }
    
    //share article
    function aaarticle(bytes32 _title,string _content) public
    canProfile(msg.sender)
    lengthLim(_content){
        articles[IDs[msg.sender]].push(article({
            title : _title,
            content : _content,
            time : now,
            exist : true
        }));
        article_count[IDs[msg.sender]] += 1;
    }
    
    //set profile photo
    function setProfile(string _profile) public
    lengthLim(_profile)
    canProfile(msg.sender){
        info[IDs[msg.sender]].profile = _profile;
    }
    
    //Auction functions
    
    function bidGold() public payable
    isSilver(msg.sender)
    successBid(msg.value){
        if(startTime==0){
            startTime = now;
            highestBidder = IDs[msg.sender];
            biddingPrice = msg.value;
        }else if((now-startTime)>=biddingTime && (now>startTime)){
            require(IDs[msg.sender]!=highestBidder);
            //generate last GOLDEN ID
            info[highestBidder].level = 1;
            info[highestBidder].prestige += 990;
            gold_count += 1;
            goldStore -= 1;
            goldenList[gold_count] = gold_record({
                name : highestBidder,
                price : biddingPrice,
                time : now,
                for_sell : false,
                price_for_sell : 0
            });
            info[highestBidder].index = gold_count;
            
            wallet[owner]+=biddingPrice;
            
            if(goldStore!=0) {
                //start new auction
                startTime = now;
                highestBidder = IDs[msg.sender];
                biddingPrice = msg.value;
            } else {
                //no more auctions, return mon
                wallet[msg.sender] += msg.value;
                startTime = 0;
            }
        } else {
            if( msg.value > biddingPrice){
                wallet[info[highestBidder].addr] += biddingPrice;
                highestBidder = IDs[msg.sender];
                biddingPrice = msg.value;
            } else {
                wallet[msg.sender] += msg.value;
            }
        }
    }
    
    function getGold() public {
        require( startTime!=0 );
        if((now-startTime)>=biddingTime && (now>startTime)){
            //generate last GOLDEN ID
            info[highestBidder].level = 1;
            info[highestBidder].prestige += 990;
            gold_count += 1;
            goldStore -= 1;
            goldenList[gold_count] = gold_record({
                name : highestBidder,
                price : biddingPrice,
                time : now,
                for_sell : false,
                price_for_sell : 0
            });
            info[highestBidder].index = gold_count;
            
            wallet[owner]+=biddingPrice;
            
            //auction finished
            startTime = 0;
        }
    }
    
    // set price for selling the card
    function sellGold(uint sPrice) public
    isGold(msg.sender){
        goldenList[info[IDs[msg.sender]].index].for_sell = true;
        goldenList[info[IDs[msg.sender]].index].price_for_sell = sPrice;
    }
    
    function cancelSellGold() public
    isGold(msg.sender){
        goldenList[info[IDs[msg.sender]].index].for_sell = false;
    }
    
    function buyGold(uint aim) public payable
    activeUser(IDs[msg.sender]) 
    notGold(msg.sender)
    forsell(aim,msg.value){
        address seller_address = info[goldenList[aim].name].addr;
        goldenList[aim].time = now;
        goldenList[aim].for_sell = false;
        info[goldenList[aim].name].level = 2;
        goldenList[aim].name = IDs[msg.sender];
        info[IDs[msg.sender]].level = 1;
        info[IDs[msg.sender]].index = aim;
        
        uint tax = msg.value / 20;
        wallet[owner] += tax;
        wallet[seller_address] += (msg.value-tax);
    }
    
    
    //withdraw money
    function withdraw() public
    activeUser(IDs[msg.sender]){
        uint balance = wallet[msg.sender];
        wallet[msg.sender] = 0;
        msg.sender.transfer(balance);
    }
    
    
    //control functions
    //freeze an account
    function freeze(bytes24 aim) public
    isOwner(msg.sender)
    activeUser(aim){
        info[aim].active = false;
    }
    
    //unfreeze an account
    function unfreeze(bytes24 aim) public
    isOwner(msg.sender)
    nameUsed(aim){
        info[aim].active = true;
    }
    
    //set card price, for golden card it's the auction entrance fee
    function setPrice(uint _level, uint _price) public
    isOwner(msg.sender){
        FEE[_level] = _price;
    }

    //set biddingTime
    function setBiddingTime(uint _time) public
    isOwner(msg.sender){
        biddingTime = _time;
    }

    //set basic length limit
    function setLimit(uint _length) public
    isOwner(msg.sender){
        lengthLimit = _length;
    }
}
