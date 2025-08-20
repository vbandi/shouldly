namespace Shouldly.Tests.ShouldContain;

public class SameElementsScenario
{
    [Fact]
    public void ShouldPass()
    {
        new[] { 1, 2, 3 }.ShouldContainSameElementsAs([3, 1, 2]);
    }

    [Fact]
    public void ShouldPassWithDuplicates()
    {
        new[] { 1, 2, 2, 3 }.ShouldContainSameElementsAs([3, 2, 1, 2]);
    }

    [Fact]
    public void ShouldPassWithComparer()
    {
        var comparison1 = new[]
        {
            new TestHelpers.ComparableClass { Property = "Elephant", IgnoredProperty = "Duck" },
            new TestHelpers.ComparableClass { Property = "Lion", IgnoredProperty = "Whale" }
        };
        var comparison2 = new[]
        {
            new TestHelpers.ComparableClass { Property = "Lion", IgnoredProperty = "Dog" },
            new TestHelpers.ComparableClass { Property = "Elephant", IgnoredProperty = "Cat" }
        };

        comparison1.ShouldContainSameElementsAs(comparison2, new TestHelpers.ComparableClassComparer());
    }

    [Fact]
    public void ShouldFailWhenElementsMissing()
    {
        Verify.ShouldFail(() =>
                new[] { 1, 2, 3 }.ShouldContainSameElementsAs([1, 2, 4], "Some additional context"),

            errorWithSource:
            """
            new[] { 1, 2, 3 }
                should contain same elements as
            [1, 2, 4]
                but was actually
            [1, 2, 3]

            Additional Info:
                Some additional context
            """,

            errorWithoutSource:
            """
            [1, 2, 3]
                should contain same elements as
            [1, 2, 4]
                but was actually
            [1, 2, 3]

            Additional Info:
                Some additional context
            """);
    }

    [Fact]
    public void ShouldFailWhenDifferentCounts()
    {
        Verify.ShouldFail(() =>
                new[] { 1, 2, 3 }.ShouldContainSameElementsAs([1, 2], "Some additional context"),

            errorWithSource:
            """
            new[] { 1, 2, 3 }
                should contain same elements as
            [1, 2]
                but was actually
            [1, 2, 3]

            Additional Info:
                Some additional context
            """,

            errorWithoutSource:
            """
            [1, 2, 3]
                should contain same elements as
            [1, 2]
                but was actually
            [1, 2, 3]

            Additional Info:
                Some additional context
            """);
    }

    [Fact]
    public void ShouldFailWithComparer()
    {
        var comparison1 = new[]
        {
            new TestHelpers.ComparableClass { Property = "Kangaroo", IgnoredProperty = "Whale" },
            new TestHelpers.ComparableClass { Property = "Tiger", IgnoredProperty = "Salmon" }
        };
        var comparison2 = new[]
        {
            new TestHelpers.ComparableClass { Property = "Snake", IgnoredProperty = "Platypus" },
            new TestHelpers.ComparableClass { Property = "Tiger", IgnoredProperty = "Duck" }
        };

        Verify.ShouldFail(() =>
                comparison1.ShouldContainSameElementsAs(comparison2, new TestHelpers.ComparableClassComparer(), "Some additional context"),

            errorWithSource:
            """
            comparison1
                should contain same elements as
            [Shouldly.Tests.TestHelpers.ComparableClass (000000), Shouldly.Tests.TestHelpers.ComparableClass (000000)]
                but was actually
            [Shouldly.Tests.TestHelpers.ComparableClass (000000), Shouldly.Tests.TestHelpers.ComparableClass (000000)]

            Additional Info:
                Some additional context
            """,

            errorWithoutSource:
            """
            [Shouldly.Tests.TestHelpers.ComparableClass (000000), Shouldly.Tests.TestHelpers.ComparableClass (000000)]
                should contain same elements as
            [Shouldly.Tests.TestHelpers.ComparableClass (000000), Shouldly.Tests.TestHelpers.ComparableClass (000000)]
                but was actually
            [Shouldly.Tests.TestHelpers.ComparableClass (000000), Shouldly.Tests.TestHelpers.ComparableClass (000000)]

            Additional Info:
                Some additional context
            """);
    }
}