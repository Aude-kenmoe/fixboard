import request, { uploadRequest } from './client';

/**
 * Returns { data: Post[], pagination: { page, limit, total, totalPages } }
 */
export function listPosts({ tag, page = 1, limit = 20 } = {}) {
  const params = new URLSearchParams();
  if (tag) params.set('tag', tag);
  params.set('page', String(page));
  params.set('limit', String(limit));
  return request(`/posts?${params.toString()}`);
}

export function getMyPosts() {
  return request('/posts/mine');
}

export function getPost(id) {
  return request(`/posts/${id}`);
}

export function createPost(payload) {
  return request('/posts', { method: 'POST', body: payload });
}

export function addComment(postId, { content, parent_comment_id }) {
  return request(`/posts/${postId}/comments`, {
    method: 'POST',
    body: { content, parent_comment_id },
  });
}

export function solvePost(postId, commentId) {
  return request(`/posts/${postId}/solve`, {
    method: 'PATCH',
    body: { comment_id: commentId },
  });
}

export function uploadAttachment(postId, file, kind) {
  const formData = new FormData();
  formData.append('kind', kind);
  formData.append('file', file);
  return uploadRequest(`/posts/${postId}/attachments`, formData);
}

export function deletePost(postId) {
  return request(`/posts/${postId}`, { method: 'DELETE' });
}

export function deleteComment(postId, commentId) {
  return request(`/posts/${postId}/comments/${commentId}`, { method: 'DELETE' });
}
