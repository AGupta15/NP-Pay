pragma solidity ^0.4.19;

import "./solutionverifier.sol";

contract BalanceResolver is SolutionVerifier {
    
    // minimum time window during which the network can vote on the solution
    uint cooldown_period = 1 minutes;
    
    // returns the money that the address is entitled to
    function get_balance() public view returns (uint){
        return balance[msg.sender];
    }
    
    // problem solver requests to get the reward after correctly solving the problem
    function request_reward(uint problemId, uint solutionId) public {
        // the problem must exist
        require(sat_problems.length > problemId);
        // the solution must exist
        require(solutions_SAT[problemId].length > solutionId);
        Problem_SAT memory problem = sat_problems[problemId];
        SATSolution memory solution = solutions_SAT[problemId][solutionId];
        // caller must be the one who proposed the solution
        require(solution.solver == msg.sender);
        // cooldown period must have passed
        require(solution.time_sol_proposed + cooldown_period < now);
        require (!problem.solved);
        // TODO check that the solution is proposed the first
        bool verified_and_correct = solution_is_verified[problemId][solutionId] && solution_is_correct[problemId][solutionId];
        bool no_dissent = (downvotes_SAT[problemId][solutionId].length == 0);
        if (verified_and_correct || no_dissent) {
            balance[solution.solver] += problem.reward;
            problem.solved = true;
            if (no_dissent) {
                // return vote deposit to up-voters
                address[] memory up_voters = upvotes_SAT[problemId][solutionId];
                for (uint i = 0; i<up_voters.length; i++) {
                    balance[up_voters[i]] += vote_deposit;
                }
            }
        }
    }
    
    // retrieve money from balance
    function retrieve_reward() public {
        uint amt = balance[msg.sender];
        balance[msg.sender] = 0;
        msg.sender.transfer(amt);
    }
}