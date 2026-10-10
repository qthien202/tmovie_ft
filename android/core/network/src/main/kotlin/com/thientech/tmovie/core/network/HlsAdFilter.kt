package com.thientech.tmovie.core.network

/**
 * Strips ads that the stream providers splice into HLS media playlists.
 *
 * KKPhim / OPhim streams insert ads as runs of segments wrapped in `#EXT-X-DISCONTINUITY`
 * tags, served from a different path than the film itself (e.g. `convertv8/x.ts` or
 * `/v8/<hash>/segment_0001.ts` among bare `abc123.ts` segments). The joins also make players
 * stall or desync. This drops every discontinuity-delimited block whose segments all come from
 * a path other than the film's, and the discontinuity tags around them.
 *
 * Master playlists and playlists without discontinuities pass through unchanged, and nothing is
 * removed if it would cut more than a quarter of the running time.
 */
object HlsAdFilter {
    private const val DISCONTINUITY = "#EXT-X-DISCONTINUITY"

    private class Block(val lines: List<String>) {
        val segments = lines.filter { it.isNotBlank() && !it.startsWith("#") }
        val duration = lines.filter { it.startsWith("#EXTINF:") }
            .sumOf { it.removePrefix("#EXTINF:").substringBefore(',').toDoubleOrNull() ?: 0.0 }
    }

    /** Directory part of a segment URI: "" for "abc.ts", "convertv8" for "convertv8/x.ts". */
    private fun dirOf(segment: String) = segment.substringBefore('?').substringBeforeLast('/', "")

    fun clean(playlist: String): String {
        if ("#EXT-X-STREAM-INF" in playlist || DISCONTINUITY !in playlist) return playlist
        val lines = playlist.lines()
        val headerEnd = lines.indexOfFirst { it.startsWith("#EXTINF") || it == DISCONTINUITY }.takeIf { it >= 0 } ?: return playlist
        val header = lines.take(headerEnd)
        val endList = lines.drop(headerEnd).any { it.trim() == "#EXT-X-ENDLIST" }

        // Split the body into blocks at each discontinuity.
        val blocks = mutableListOf<Block>()
        var current = mutableListOf<String>()
        for (line in lines.drop(headerEnd)) {
            when (line.trim()) {
                DISCONTINUITY -> { if (current.isNotEmpty()) blocks += Block(current); current = mutableListOf() }
                "#EXT-X-ENDLIST" -> Unit
                else -> current += line
            }
        }
        if (current.isNotEmpty()) blocks += Block(current)

        // The film's segments live in the directory that holds the most segments.
        val mainDir = blocks.flatMap { it.segments }.groupingBy(::dirOf).eachCount().maxByOrNull { it.value }?.key ?: return playlist
        val (kept, dropped) = blocks.partition { b -> b.segments.isEmpty() || b.segments.any { dirOf(it) == mainDir } }
        if (dropped.isEmpty()) return playlist
        val total = blocks.sumOf { it.duration }
        if (total <= 0 || dropped.sumOf { it.duration } > total / 4) return playlist

        // Rejoin; keep a discontinuity only between two kept blocks that were separate in the source.
        val out = ArrayList<String>(lines.size)
        out += header
        kept.filter { it.segments.isNotEmpty() || it.lines.any { l -> l.isNotBlank() } }.forEachIndexed { i, b ->
            if (i > 0) out += DISCONTINUITY
            out += b.lines.filter { it.isNotBlank() }
        }
        if (endList) out += "#EXT-X-ENDLIST"
        return out.joinToString("\n", postfix = "\n")
    }
}
