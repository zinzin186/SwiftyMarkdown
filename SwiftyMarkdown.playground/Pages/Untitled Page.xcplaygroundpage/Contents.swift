var nums = [10, 20, 30, 40, 50]
nums.replaceSubrange(1...1, with: repeatElement(1, count: 5))
print(nums)
