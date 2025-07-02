using System.Collections.Generic;

namespace YoutubeDownloader.Utils.Extensions;

public static class EnumerableExtensions
{
    /// <summary>
    /// Returns an enumeration of tuples containing the index and the original item.
    /// </summary>
    public static IEnumerable<(int Index, T Value)> Index<T>(this IEnumerable<T> source)
    {
        int index = 0;
        foreach (var item in source)
        {
            yield return (index++, item);
        }
    }
}
