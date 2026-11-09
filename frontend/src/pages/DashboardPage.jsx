import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Inbox, Plus } from 'lucide-react';
import { listPosts } from '../api/posts';
import { listTags } from '../api/tags';
import TagFilter from '../components/TagFilter';
import PostRow from '../components/PostRow';
import Spinner from '../components/Spinner';
import EmptyState from '../components/EmptyState';
import Button from '../components/Button';

const PAGE_SIZE = 20;

export default function DashboardPage() {
  const navigate = useNavigate();
  const [tags, setTags] = useState([]);
  const [activeTag, setActiveTag] = useState(null);
  const [posts, setPosts] = useState([]);
  const [pagination, setPagination] = useState(null);
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    listTags().then(setTags).catch(() => {});
  }, []);

  useEffect(() => {
    setLoading(true);
    setError('');
    listPosts({ tag: activeTag, page, limit: PAGE_SIZE })
      .then((result) => {
        setPosts(result.data);
        setPagination(result.pagination);
      })
      .catch((err) => setError(err.message))
      .finally(() => setLoading(false));
  }, [activeTag, page]);

  // Reset to page 1 when tag filter changes
  function handleTagChange(tag) {
    setActiveTag(tag);
    setPage(1);
  }

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight text-text">Dashboard</h1>
        <p className="mt-1 text-sm text-text-muted">
          Browse troubleshooting threads from your cohort.
        </p>
      </div>

      <TagFilter tags={tags} active={activeTag} onChange={handleTagChange} />

      {loading && <Spinner label="Loading posts\u2026" full />}

      {!loading && error && (
        <EmptyState
          icon={Inbox}
          title="Couldn't load posts"
          description={error}
        />
      )}

      {!loading && !error && posts.length === 0 && (
        <EmptyState
          icon={Inbox}
          title={activeTag ? `No posts tagged "\${activeTag}" yet` : 'No posts yet'}
          description="Be the first to post a problem and start building the knowledge base."
          action={
            <Button onClick={() => navigate('/posts/new')}>
              <Plus size={16} />
              New Post
            </Button>
          }
        />
      )}

      {!loading && !error && posts.length > 0 && (
        <>
          <div className="divide-y divide-border overflow-hidden rounded-xl border border-border bg-surface">
            {posts.map((post) => (
              <PostRow
                key={post.id}
                post={post}
                onDeleted={(id) => setPosts((prev) => prev.filter((p) => p.id !== id))}
              />
            ))}
          </div>

          {pagination && pagination.totalPages > 1 && (
            <div className="flex items-center justify-between text-sm text-text-muted">
              <span>
                Page {pagination.page} of {pagination.totalPages} &mdash; {pagination.total} posts
              </span>
              <div className="flex gap-2">
                <button
                  className="px-3 py-1.5 rounded border border-border disabled:opacity-40 hover:bg-surface-hover"
                  disabled={pagination.page <= 1}
                  onClick={() => setPage((p) => p - 1)}
                >
                  &#8592; Prev
                </button>
                <button
                  className="px-3 py-1.5 rounded border border-border disabled:opacity-40 hover:bg-surface-hover"
                  disabled={pagination.page >= pagination.totalPages}
                  onClick={() => setPage((p) => p + 1)}
                >
                  Next &#8594;
                </button>
              </div>
            </div>
          )}
        </>
      )}
    </div>
  );
}
