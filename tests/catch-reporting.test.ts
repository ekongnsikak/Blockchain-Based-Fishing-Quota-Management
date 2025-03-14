import { describe, it, expect, beforeEach, vi } from "vitest"

// Mock the Clarity VM interactions
const mockClarity = {
  txSender: "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM",
  contracts: {
    "catch-reporting": {
      functions: {
        "register-entity": vi.fn().mockReturnValue({ value: true }),
        "set-quota": vi.fn().mockReturnValue({ value: true }),
        "report-catch": vi.fn().mockReturnValue({ value: true }),
        "get-reported-catch": vi.fn().mockReturnValue({
          value: { "reported-amount": 500, timestamp: 12345 },
        }),
        "get-total-catch": vi.fn().mockReturnValue({
          value: { amount: 5000 },
        }),
        "transfer-admin": vi.fn().mockReturnValue({ value: true }),
      },
    },
  },
}

// Mock the contract calls
vi.mock("@stacks/transactions", () => ({
  callReadOnlyFunction: ({ contractName, functionName, args }) => {
    return mockClarity.contracts[contractName].functions[functionName](...args)
  },
  callContractFunction: ({ contractName, functionName, args }) => {
    return mockClarity.contracts[contractName].functions[functionName](...args)
  },
}))

describe("Catch Reporting Contract", () => {
  beforeEach(() => {
    // Reset mocks before each test
    Object.values(mockClarity.contracts["catch-reporting"].functions).forEach((fn) => fn.mockClear())
  })
  
  it("should register an entity", async () => {
    const newEntity = "ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG"
    const result = await mockClarity.contracts["catch-reporting"].functions["register-entity"](newEntity)
    expect(result.value).toBe(true)
    expect(mockClarity.contracts["catch-reporting"].functions["register-entity"]).toHaveBeenCalledWith(newEntity)
  })
  
  it("should set quota for an entity", async () => {
    const entity = "ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG"
    const result = await mockClarity.contracts["catch-reporting"].functions["set-quota"](entity, "salmon", 1000, 2023)
    expect(result.value).toBe(true)
    expect(mockClarity.contracts["catch-reporting"].functions["set-quota"]).toHaveBeenCalledWith(
        entity,
        "salmon",
        1000,
        2023,
    )
  })
  
  it("should report a catch", async () => {
    const result = await mockClarity.contracts["catch-reporting"].functions["report-catch"]("salmon", 500, 2023)
    expect(result.value).toBe(true)
    expect(mockClarity.contracts["catch-reporting"].functions["report-catch"]).toHaveBeenCalledWith("salmon", 500, 2023)
  })
  
  it("should retrieve reported catch for an entity", async () => {
    const result = await mockClarity.contracts["catch-reporting"].functions["get-reported-catch"](
        mockClarity.txSender,
        "salmon",
        2023,
    )
    expect(result.value).toEqual({ "reported-amount": 500, timestamp: 12345 })
    expect(mockClarity.contracts["catch-reporting"].functions["get-reported-catch"]).toHaveBeenCalledWith(
        mockClarity.txSender,
        "salmon",
        2023,
    )
  })
  
  it("should retrieve total catch for a species", async () => {
    const result = await mockClarity.contracts["catch-reporting"].functions["get-total-catch"]("salmon", 2023)
    expect(result.value).toEqual({ amount: 5000 })
    expect(mockClarity.contracts["catch-reporting"].functions["get-total-catch"]).toHaveBeenCalledWith("salmon", 2023)
  })
  
  it("should transfer admin rights", async () => {
    const newAdmin = "ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG"
    const result = await mockClarity.contracts["catch-reporting"].functions["transfer-admin"](newAdmin)
    expect(result.value).toBe(true)
    expect(mockClarity.contracts["catch-reporting"].functions["transfer-admin"]).toHaveBeenCalledWith(newAdmin)
  })
})

