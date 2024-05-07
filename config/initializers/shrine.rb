require 'shrine'

require "shrine/storage/file_system"
Shrine.storages = {
  cache: Shrine::Storage::FileSystem.new("public", prefix: "uploads/cache"),
  store: Shrine::Storage::FileSystem.new("public", prefix: "uploads/store"),
  public_cache: Shrine::Storage::FileSystem.new("public", prefix: "uploads/public_cache"),
  public_store: Shrine::Storage::FileSystem.new("public", prefix: "uploads/public_store")
}

Shrine.plugin :mongoid