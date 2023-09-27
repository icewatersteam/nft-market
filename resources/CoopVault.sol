// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../lib/FixedPoint.sol";
import "../tokens/H2OToken.sol";

// import erc20 token
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CoopVault {
    // Use Fixed Point library for decimal ints.
    using UFixedPoint for uint256;
    using SFixedPoint for int256;

    H2OToken public h2oToken;
    uint256 public totalPatronage;
    uint256 public withdrawalPeriod;
    uint256 public lastResetTime;
    uint256 public disburseAmount; //treasury amount at time of reset
    uint256 public decayRate; //rate of decay in H2O per second
    address public coopController;

    mapping(address => uint256) public patronage;
    mapping(address => uint256) public lastWithdrawal;

    event Withdrawal(address indexed to, uint256 value);
    event AddPatronage(address indexed to, uint256 value);
    event ResetDisbursement();

    constructor(H2OToken _h2oToken, address _coopController) {
        h2oToken = _h2oToken;
        withdrawalPeriod = 30 days;
        lastResetTime = block.timestamp;

        // 1% decay rate per month.
        decayRate = 1e16 / uint256(30 days);
        coopController = _coopController;
    }

    modifier onlyCoopController() {
        require(msg.sender == coopController, "Only CoopController can call this function.");
        _;
    }

    modifier onlyMember() {
        require(patronage[msg.sender] > 0, "Only members can call this function.");
        _;
    }

    function getPatronageOf(address _member) public view returns (uint256) {
        return patronage[_member];
    }

    // Note: This should be restricted to the Coop address
    function addPatronage(address _to, uint256 _value) external onlyCoopController {
        patronage[_to] += _value;
        totalPatronage += _value;
        emit AddPatronage(_to, _value);
    }

    function withdraw() public onlyMember {
        uint256 memberLastWithdrawal = lastWithdrawal[msg.sender];
        require(memberLastWithdrawal < lastResetTime, "Already withdrawn this period");
        lastWithdrawal[msg.sender] = block.timestamp;

        // Withdraw share of tokens.
        uint256 share = patronage[msg.sender].div(totalPatronage);
        uint256 value = share.mul(disburseAmount);
        h2oToken.transfer(msg.sender, value);

        // Decay patronage.
        uint256 timeSinceLastWithdrawal = block.timestamp - memberLastWithdrawal;
        uint256 patronageDecay = patronage[msg.sender].mul(decayRate).mul(timeSinceLastWithdrawal);
        patronage[msg.sender] -= patronageDecay;  
        totalPatronage -= patronageDecay;    

        emit Withdrawal(msg.sender, value);
    }

    function resetDisbursement(uint256 _value) public {
        require(block.timestamp > lastResetTime + withdrawalPeriod, "Not time to reset yet");
        lastResetTime = block.timestamp;

        if (_value > 0) {
            h2oToken.transferFrom(msg.sender, address(this), _value);
        }

        disburseAmount = h2oToken.balanceOf(address(this));

        emit ResetDisbursement();
    }

}