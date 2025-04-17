'discover':
    r'''LET $liked_posts = (SELECT ->(like WHERE createdAt > (time::now() - 168h) AND meta::tb(out) == 'post') as likes FROM $feeduserdid).likes.out;
LET $liked_posts2 = (SELECT * FROM (SELECT id, type::thing('like_count_view', [id]).likeCount AS likeCount FROM $liked_posts) WHERE likeCount > 1 ORDER BY likeCount ASC LIMIT 64).id;

LET $tmp1 = array::flatten((SELECT <-like<-did AS curators FROM $liked_posts2).curators);
LET $curators = SELECT id,score FROM (SELECT id,count() as score FROM $tmp1 GROUP BY id) WHERE id != $feeduserdid ORDER BY score DESC LIMIT 64;

-- Blocklist adjustment
LET $blocklist = [did:plc_xxno7p4xtpkxtn4ok6prtlcb,did:plc_nykin5up57yvdzicmonul4uk,did:plc_z6srowwqbz4srzh4vxqigdp5];

LET $curators_filtered = SELECT id,score FROM $curators WHERE $blocklist CONTAINSNOT id;

LET $new_likes = SELECT *,->(like WHERE createdAt > (time::now() - 6h) AND meta::tb(out) == 'post') as likes FROM $curators_filtered;
LET $another_var = SELECT id,score,(SELECT out, createdAt from $parent.likes ORDER BY createdAt DESC LIMIT 32).out AS likes FROM $new_likes;

LET $posts = array::flatten((SELECT (SELECT id, $parent.score AS score FROM $parent.likes) AS posts FROM $another_var).posts);
LET $liked_posts4 = SELECT id, math::sum(score) as totalScore FROM $posts GROUP BY id ORDER BY totalScore DESC LIMIT 500;

-- Fix to prioritize newest posts
SELECT id FROM $liked_posts4 WHERE $liked_posts CONTAINSNOT id ORDER BY createdAt DESC;
''',

'catch-up':
    r'select subject as id, likeCount from like_count_view where likeCount > 68 and subject.createdAt > (time::now() - 24h) order by subject.createdAt desc, likeCount desc limit 1000;',

'catch-up-weekly':
    r'select subject as id, likeCount from like_count_view where likeCount > 130 and subject.createdAt > (time::now() - 168h) order by subject.createdAt desc, likeCount desc limit 1000;',

'art-new':
    r'''LET $artists = (select ->follow.out as following from did:plc_y7crv2yh74s7qhmtx3mvbgv5).following;
LET $posts = array::flatten(array::flatten((SELECT (SELECT ->posts.out as posts FROM $parent.id) AS posts FROM $artists).posts.posts));
LET $reposts = (SELECT ->repost.out as reposts FROM did:plc_y7crv2yh74s7qhmtx3mvbgv5).reposts;
LET $hashtag_posts = (SELECT ->usedin.out AS posts FROM hashtag:art).posts;
return SELECT id,createdAt FROM array::distinct(array::concat($hashtag_posts,array::concat($posts,$reposts))) WHERE count(images) > 0 ORDER BY createdAt DESC LIMIT 1000;
''',

'mutuals':
    r'''LET $res = (select ->follow.out as following, <-follow.in as follows from $feeduserdid);
LET $mutuals = array::intersect($res.follows, $res.following);
SELECT id,createdAt FROM array::flatten(array::flatten((SELECT (SELECT ->(posts WHERE createdAt > (time::now() - 168h)).out as posts FROM $parent.id) AS posts FROM $mutuals).posts.posts)) ORDER BY createdAt DESC LIMIT 1000;''',

're-plus-posts':
    r'''
LET $following = (select ->follow.out as following FROM $feeduserdid).following;

LET $reposts = SELECT id as repost,out as id,createdAt FROM array::flatten(array::flatten((SELECT (SELECT ->(repost WHERE createdAt > (time::now() - 24h)) as reposts FROM $parent.id) AS reposts FROM $following).reposts.reposts));
LET $posts = SELECT id,createdAt FROM array::flatten(array::flatten((SELECT (SELECT ->(posts WHERE createdAt > (time::now() - 24h)).out as posts FROM $parent.id) AS posts FROM $following).posts.posts));

SELECT * FROM array::concat($reposts,$posts) ORDER BY createdAt DESC LIMIT 1000;
''',

'only-posts':
    r'''LET $following = (select ->follow.out as following FROM $feeduserdid).following;
SELECT id,createdAt FROM array::flatten(array::flatten((SELECT (SELECT ->(posts WHERE createdAt > (time::now() - 72h)).out as posts FROM $parent.id) AS posts FROM $following).posts.posts)) ORDER BY createdAt DESC LIMIT 1000;''',

'whats-warm':
    r'SELECT subject as id, subject.createdAt as createdAt FROM like_count_view WHERE likeCount > 5 AND subject.createdAt > (time::now() - 1h) order by createdAt desc;',

'whats-reposted':
    r'select id,createdAt from post where parent == NONE and createdAt > (time::now() - 6h) and count(<-repost) > 4 order by createdAt desc;',
