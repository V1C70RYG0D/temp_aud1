// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IUtils} from "./interfaces/IUtils.sol";
import {Errors} from "./libs/Errors.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {IRewardProtocol} from "./interfaces/IRewardProtocol.sol";


/// @title Eloop Upgradeable Reward Protocol
/// @notice This contract enables users to stake Eloop security tokens to earn rewards over time. 
///         It features a detailed reward distribution system that tracks each staker's share of the total staked tokens and calculates their rewards based on the proportion of their stake. 
/// @dev Extends OpenZeppelin's ERC20 for token handling, AccessControl for role management, and includes Pausable functionality. It utilizes a magnified reward per share approach to calculate rewards efficiently and accurately over time. This contract is part of the Eloop ecosystem, designed to provide users with a secure and transparent way to earn rewards by staking their tokens.
contract EloopRewardProtocol is
    ERC20Upgradeable,
    AccessControlUpgradeable,
    IRewardProtocol,
    UUPSUpgradeable,
    PausableUpgradeable
{
    /// A constant to facilitate calculations with higher precision
    uint256 internal constant MAGNITUDE = 2 ** 128;

    uint256 internal magnifiedRewardPerShare;
    IERC20 public securityToken;
    IERC20 public rewardToken;
    uint256 public lastRewardTime;
    bytes32 public constant EXTERNAL_BOT = keccak256("EXTERNAL_BOT");
    mapping(address account => int256 rewardCorrection) internal magnifiedRewardCorrections;
    mapping(address account => uint256 withdrawnReward) internal withdrawnRewards;
    IUtils public utils;

    /// Modifier to check if the caller is an admin or a bot.
    modifier adminOrBotCheck() {
        if (
            !hasRole(DEFAULT_ADMIN_ROLE, msg.sender) &&
            !hasRole(EXTERNAL_BOT, msg.sender)
        ) revert Errors.NotAdminOrBot();
        _;
    }

    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializer for Eloop Staking Protocol
     * @param securityTokenAddr_ Address of the security token (staked token)
     * @param rewardTokenAddr_ Address of the reward token
     * @param utils_ Address of the utils contract for whitelisting
     * @param name_ Name of the staking token
     * @param symbol_ Symbol of the staking token
     */
     function initialize(
        address securityTokenAddr_,
        address rewardTokenAddr_,
        address utils_,
        string memory name_,
        string memory symbol_
    ) public initializer {
        __ERC20_init(name_, symbol_);
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        if (
            securityTokenAddr_ == address(0) ||
            rewardTokenAddr_ == address(0) ||
            utils_ == address(0)
        ) revert Errors.InvalidAddress();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        securityToken = IERC20(securityTokenAddr_);
        rewardToken = IERC20(rewardTokenAddr_);
        utils = IUtils(utils_);  
        lastRewardTime = 0;
    }

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    /**
     * @dev Distributes rewards to stakers
     * @param amount The amount of rewards to distribute
     * Can only be called by an admin role
     */
    function distributeRewards(uint256 amount)
        external
        adminOrBotCheck
    {
        if (totalSupply() == 0) revert Errors.TotalSupplyZero();
        if (amount == 0) revert Errors.AmountZero(); //@audit no upper limit on amount variable (rewardReleased >= MAX_REWARD
        rewardToken.transferFrom(msg.sender, address(this), amount);
        magnifiedRewardPerShare += (amount * MAGNITUDE) / totalSupply();
        lastRewardTime = block.timestamp; //@audit we are never using this variable anywhere,
        emit RewardsDistributed(msg.sender, amount);
    }

    /** 
    @audit
    missing implementation for previeving or calculating  rewards to distribute


    /// @notice The ```calculateRewardsToDistribute``` function calculates the amount of rewards to distribute based on the rewards cycle data and the time elapsed
    /// @param _rewardsCycleData The rewards cycle data
    /// @param _deltaTime The time elapsed since the last rewards distribution
    /// @return _rewardToDistribute The amount of rewards to distribute
    function calculateRewardsToDistribute(
        RewardsCycleData memory _rewardsCycleData,
        uint256 _deltaTime
    ) public view virtual returns (uint256 _rewardToDistribute) {
        _rewardToDistribute =
            (_rewardsCycleData.rewardCycleAmount * _deltaTime) /
            (_rewardsCycleData.cycleEnd - _rewardsCycleData.lastSync);
    }

    /// @notice The ```previewDistributeRewards``` function is used to preview the rewards distributed at the top of the block
    /// @return _rewardToDistribute The amount of underlying to distribute
    function previewDistributeRewards() public view virtual returns (uint256 _rewardToDistribute) {
        // Cache state for gas savings
        RewardsCycleData memory _rewardsCycleData = rewardsCycleData;
        uint256 _lastRewardsDistribution = lastRewardsDistribution;
        uint40 _timestamp = block.timestamp.safeCastTo40();

        // Calculate the delta time, but only include up to the cycle end in case we are passed it
        uint256 _deltaTime = _timestamp > _rewardsCycleData.cycleEnd
            ? _rewardsCycleData.cycleEnd - _lastRewardsDistribution
            : _timestamp - _lastRewardsDistribution;

        // Calculate the rewards to distribute
        _rewardToDistribute = calculateRewardsToDistribute({
            _rewardsCycleData: _rewardsCycleData,
            _deltaTime: _deltaTime
        });
    }
     */

    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}

    /**
     * @dev Allows a user to withdraw their rewards
     * Rewards are transferred from the contract to the caller's address
     */
    function withdrawReward() external {
        uint256 _withdrawableReward = withdrawableRewardOf(msg.sender);
        //if(_withdrawableReward <= 0) revert Errors.AmountZero();
        if (_withdrawableReward > 0) {
            withdrawnRewards[msg.sender] += _withdrawableReward;
            emit RewardWithdrawn(msg.sender, _withdrawableReward);
            rewardToken.transfer(msg.sender, _withdrawableReward);
        }
    }
    /**
    * @dev Shows how much rewards is avaiable to withdraw
    * @param owner Address of the stake token owner to check
    */
    function withdrawableRewardOf(address owner)
        public
        view
        returns (uint256)
    {
        return accumulativeRewardOf(owner) - withdrawnRewards[owner];
    }

    /**
    * @dev Shows the withdrawn Reward of an user
    */
    function withdrawnRewardOf(address owner) external view returns (uint256) {
        return withdrawnRewards[owner];
    }

    function accumulativeRewardOf(address owner)
        public
        view
        returns (uint256)
    {
        int256 magnifiedReward = SafeCast.toInt256(
            magnifiedRewardPerShare * balanceOf(owner)
        );
        int256 correctedReward = magnifiedReward +
            magnifiedRewardCorrections[owner];
        // solhint-disable-next-line var-name-mixedcase
        uint256 Reward = SafeCast.toUint256(correctedReward) / MAGNITUDE;
        return Reward;
    }

    /**
    * @dev Shows how much rewards is avaiable to withdraw
    * @param owner Address of the stake token owner to check
    */
    function rewardOf(address owner) public view returns (uint256) {
        return withdrawableRewardOf(owner);
    }

    /**
    * @dev Transfer function
    */
    function transfer(
        address to,
        uint256 value
    ) override public returns(bool success) {
        if (utils.checkTransfer(address(this), msg.sender, to, value) != 0) {
            revert Errors.TransferRestricted();
        }
        _transfer(msg.sender, to, value);

        int256 _magCorrection = SafeCast.toInt256(
            magnifiedRewardPerShare * value
        );
        magnifiedRewardCorrections[msg.sender] += _magCorrection;
        magnifiedRewardCorrections[to] -= _magCorrection;
        return true;
    }

    /**
    * @dev Transfer function
    */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) override public returns(bool success){
        if (utils.checkTransfer(address(this), from, to, value) != 0) {
            revert Errors.TransferRestricted();
        }
        _transfer(from, to, value);

        int256 _magCorrection = SafeCast.toInt256(
            magnifiedRewardPerShare * value
        );
        magnifiedRewardCorrections[from] += _magCorrection;
        magnifiedRewardCorrections[to] -= _magCorrection;
        return true;
    }
    /**
    * @dev Allows users to stake their security tokens in exchange for staking tokens.
    * @param amount The amount of security tokens to be staked by the caller.
    */
    function stake(uint256 amount) external whenNotPaused {
        if (amount == 0) revert Errors.AmountZero();
        // Transfer the tokens to the staking protocol
        securityToken.transferFrom(msg.sender, address(this), amount);
        // Mint the staking tokens
        mint(msg.sender, amount);
        emit Stake(msg.sender, amount);
    }


    /**
     * @dev Allows a user to unstake their tokens and withdraw them back to their wallet.
     * @param amount The amount of tokens to unstake.
     */
    function unstake(uint256 amount) external whenNotPaused {
        if (amount == 0) revert Errors.AmountZero();
        if (balanceOf(msg.sender) < amount) revert Errors.InsufficientBalance();

        // Burn the staked tokens to reduce the user's balance
        burn(msg.sender, amount);

        // Transfer the unstaked tokens back to the user
        securityToken.transfer(msg.sender, amount);

        emit Unstake(msg.sender, amount);
    }

    /**
     * @dev Mints staking tokens to a user's account as a representation of staked security tokens.
     * This increases the total supply of staking tokens and adjusts the user's reward correction balance.
     * @param _account The account to receive the minted staking tokens.
     * @param _value The amount of staking tokens to mint.
     * @notice Called internally during the staking process.
     */
    function mint(address _account, uint256 _value) internal {
        _mint(_account, _value);

        int256 _magCorrection = SafeCast.toInt256(
            magnifiedRewardPerShare * _value
        );
        magnifiedRewardCorrections[_account] -= _magCorrection;
    }

    /**
     * @dev Burns staking tokens from a user's account when they unstake, decreasing the total supply.
     * This action also adjusts the user's reward correction balance to ensure accurate reward calculation.
     * @param _account The account from which staking tokens will be burned.
     * @param _value The amount of staking tokens to burn.
     * @notice Called internally during the unstaking process.
     */
    function burn(address _account, uint256 _value) internal {
        _burn(_account, _value);
        int256 _magCorrection = SafeCast.toInt256(
            magnifiedRewardPerShare * _value
        );
        magnifiedRewardCorrections[_account] += _magCorrection;
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
     
}

 function transfer(address recipient, uint256 amount)
      public
      virtual
      override
      returns (bool)
  {
      _transfer(_msgSender(), recipient, amount);
      return true;
  }

  /**
    * @dev See {IERC20-transferFrom}.
    *
    * Emits an {Approval} event indicating the updated allowance. This is not
    * required by the EIP. See the note at the beginning of {ERC20}.
    *
    * Requirements:
    *
    * - `sender` and `recipient` cannot be the zero address.
    * - `sender` must have a balance of at least `amount`.
    * - the caller must have allowance for ``sender``'s tokens of at least
    * `amount`.
    */
  function transferFrom(address sender, address recipient, uint256 amount)
      public
      virtual
      override
      returns (bool)
  {
      _transfer(sender, recipient, amount);
      _approve(
          sender,
          _msgSender(),
          allowance(sender, _msgSender()).sub(
              amount,
              "ERC20: transfer amount exceeds allowance"
          )
      );
      return true;
  }

   /// @dev Internal function that transfer tokens from one address to another.
  /// Update magnifiedRewardCorrections to keep rewards unchanged.
  /// @param from The address to transfer from.
  /// @param to The address to transfer to.
  /// @param value The amount to be transferred.
  function _transfer(address from, address to, uint256 value) internal override {
    if (utils.checkTransfer(address(this), from, to, value) != 0) {
            revert Errors.TransferRestricted();
        }
    super._transfer(from, to, value);

    int256 _magCorrection = magnifiedRewardPerShare.mul(value).toInt256();
    magnifiedRewardCorrections[from] = magnifiedRewardCorrections[from].add(_magCorrection);
    magnifiedRewardCorrections[to] = magnifiedRewardCorrections[to].sub(_magCorrection);
  }
