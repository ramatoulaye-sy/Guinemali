-- =====================================================
-- Migration: Ajouter la colonne 'comments' a la table 'forum_posts'
-- Description: Stocke les commentaires au format JSON
-- =====================================================

-- Ajouter la colonne 'comments' si elle n'existe pas
ALTER TABLE public.forum_posts
ADD COLUMN IF NOT EXISTS comments JSONB DEFAULT '[]'::jsonb;

-- Creer un index pour les recherches sur les commentaires
CREATE INDEX IF NOT EXISTS idx_forum_posts_comments ON public.forum_posts USING GIN (comments);

-- Ajouter un commentaire sur la colonne
COMMENT ON COLUMN public.forum_posts.comments IS 'Liste des commentaires au format JSON (array d''objets)';
