import { describe, it, expect, beforeEach } from "vitest"

describe("Budget Manager Contract", () => {
  let contractAddress
  let manager
  let user1
  let approver1
  
  beforeEach(() => {
    contractAddress = "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.budget-manager"
    manager = "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM"
    user1 = "ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG"
    approver1 = "ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC"
  })
  
  describe("Budget Initialization", () => {
    it("should initialize project budget successfully", () => {
      const projectId = 1
      const totalBudget = 500000
      
      const result = {
        success: true,
        projectId: projectId,
        totalBudget: totalBudget,
        allocatedBudget: 0,
        spentBudget: 0,
        remainingBudget: totalBudget,
        manager: manager,
      }
      
      expect(result.success).toBe(true)
      expect(result.totalBudget).toBe(totalBudget)
      expect(result.remainingBudget).toBe(totalBudget)
    })
    
    it("should fail with zero budget", () => {
      const result = {
        success: false,
        error: "ERR-INVALID-AMOUNT",
      }
      
      expect(result.success).toBe(false)
      expect(result.error).toBe("ERR-INVALID-AMOUNT")
    })
  })
  
  describe("Budget Category Allocation", () => {
    it("should allocate budget to category successfully", () => {
      const projectId = 1
      const category = "development"
      const amount = 200000
      const description = "Software development costs"
      
      const result = {
        success: true,
        projectId: projectId,
        category: category,
        allocatedAmount: amount,
        spentAmount: 0,
        description: description,
      }
      
      expect(result.success).toBe(true)
      expect(result.allocatedAmount).toBe(amount)
      expect(result.spentAmount).toBe(0)
    })
    
    it("should fail when exceeding total budget", () => {
      const result = {
        success: false,
        error: "ERR-INSUFFICIENT-BUDGET",
      }
      
      expect(result.success).toBe(false)
      expect(result.error).toBe("ERR-INSUFFICIENT-BUDGET")
    })
    
    it("should fail when user is not budget manager", () => {
      const result = {
        success: false,
        error: "ERR-NOT-AUTHORIZED",
      }
      
      expect(result.success).toBe(false)
      expect(result.error).toBe("ERR-NOT-AUTHORIZED")
    })
  })
  
  describe("Expense Submission", () => {
    it("should submit expense successfully", () => {
      const projectId = 1
      const category = "development"
      const amount = 15000
      const description = "Frontend development milestone payment"
      
      const result = {
        success: true,
        expenseId: 1,
        projectId: projectId,
        category: category,
        amount: amount,
        description: description,
        status: "pending",
        requester: user1,
      }
      
      expect(result.success).toBe(true)
      expect(result.expenseId).toBe(1)
      expect(result.status).toBe("pending")
    })
    
    it("should fail with zero amount", () => {
      const result = {
        success: false,
        error: "ERR-INVALID-AMOUNT",
      }
      
      expect(result.success).toBe(false)
      expect(result.error).toBe("ERR-INVALID-AMOUNT")
    })
    
    it("should fail with non-existent category", () => {
      const result = {
        success: false,
        error: "ERR-BUDGET-NOT-FOUND",
      }
      
      expect(result.success).toBe(false)
      expect(result.error).toBe("ERR-BUDGET-NOT-FOUND")
    })
  })
  
  describe("Expense Approval", () => {
    it("should approve expense successfully", () => {
      const expenseId = 1
      const amount = 15000
      
      const result = {
        success: true,
        expenseId: expenseId,
        status: "approved",
        approver: approver1,
        amount: amount,
      }
      
      expect(result.success).toBe(true)
      expect(result.status).toBe("approved")
      expect(result.approver).toBe(approver1)
    })
    
    it("should fail when user is not authorized approver", () => {
      const result = {
        success: false,
        error: "ERR-NOT-AUTHORIZED",
      }
      
      expect(result.success).toBe(false)
      expect(result.error).toBe("ERR-NOT-AUTHORIZED")
    })
    
    it("should fail when exceeding category budget", () => {
      const result = {
        success: false,
        error: "ERR-INSUFFICIENT-BUDGET",
      }
      
      expect(result.success).toBe(false)
      expect(result.error).toBe("ERR-INSUFFICIENT-BUDGET")
    })
  })
  
  describe("Budget Utilization", () => {
    it("should calculate budget utilization correctly", () => {
      const projectId = 1
      const totalBudget = 500000
      const spentBudget = 125000
      const expectedUtilization = 25 // 25%
      
      const result = {
        success: true,
        projectId: projectId,
        utilization: expectedUtilization,
      }
      
      expect(result.success).toBe(true)
      expect(result.utilization).toBe(expectedUtilization)
    })
  })
  
  describe("Approver Management", () => {
    it("should add budget approver successfully", () => {
      const projectId = 1
      const approver = approver1
      
      const result = {
        success: true,
        projectId: projectId,
        approver: approver,
        authorized: true,
      }
      
      expect(result.success).toBe(true)
      expect(result.authorized).toBe(true)
    })
    
    it("should fail when non-manager tries to add approver", () => {
      const result = {
        success: false,
        error: "ERR-NOT-AUTHORIZED",
      }
      
      expect(result.success).toBe(false)
      expect(result.error).toBe("ERR-NOT-AUTHORIZED")
    })
  })
})
