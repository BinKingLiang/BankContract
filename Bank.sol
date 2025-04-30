// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Bank {
    // 存款记录结构体
    struct DepositRecord {
        address user;
        uint256 amount;
    }

    address public admin;                      // 管理员地址
    mapping(address => uint256) public balances; // 地址对应存款余额
    DepositRecord[3] public topDepositors;     // 存款前三名记录

    // 仅管理员权限修饰器
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    constructor() {
        admin = msg.sender; // 部署合约时设置管理员
    }

    // 接收 ETH 存款的回退函数
    receive() external payable {
        _updateDeposit(msg.sender, msg.value);
    }

    // 更新存款记录和前三名
    function _updateDeposit(address _user, uint256 _amount) private {
        balances[_user] += _amount; // 更新用户余额
        
        uint256 currentDeposit = balances[_user];
        bool existsInTop = false;

        // 检查是否已在前三名中
        for (uint i = 0; i < 3; i++) {
            if (topDepositors[i].user == _user) {
                topDepositors[i].amount = currentDeposit;
                existsInTop = true;
                break;
            }
        }

        // 若不在前三名且金额超过第三名，则替换
        if (!existsInTop && currentDeposit > topDepositors[2].amount) {
            topDepositors[2] = DepositRecord(_user, currentDeposit);
        }

        // 对前三名排序
        _sortTopDepositors();
    }

    // 前三名排序算法（冒泡排序简化版）
    function _sortTopDepositors() private {
        // 三次比较确保降序排列
        if (topDepositors[0].amount < topDepositors[1].amount) {
            (topDepositors[0], topDepositors[1]) = (topDepositors[1], topDepositors[0]);
        }
        if (topDepositors[1].amount < topDepositors[2].amount) {
            (topDepositors[1], topDepositors[2]) = (topDepositors[2], topDepositors[1]);
        }
        if (topDepositors[0].amount < topDepositors[1].amount) {
            (topDepositors[0], topDepositors[1]) = (topDepositors[1], topDepositors[0]);
        }
    }

    // 管理员提款方法
    function withdraw(uint256 _amount) external onlyAdmin {
        require(address(this).balance >= _amount, "Insufficient balance");
        (bool success, ) = payable(admin).call{value: _amount}("");
        require(success, "Withdrawal failed");
    }

    // 获取合约总余额（可选功能）
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
