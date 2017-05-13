# Heroku Deploy
[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/umisora/line_notify_bot)

# README
Line Push Message Botです。

例えばSlack のOutgoing WebhooksでこのBotをキックすると
LINEに通知が飛ぶような、任意のWebhookを受けてLineに通知するBotです。

受信可能なサービス
* Backlog

# Whitelist
通知先(LineUser識別子)はホワイトリストに定義します。
識別子はLineで友達になった後に `id` と話しかけると教えてくれる仕様にします

# 補足
家庭で使用する目的なので自己中心的なメンテナンスになりますことご容赦ください

# 参考
http://qiita.com/fullmated/items/81d1a49ed3d49eda2285

# 動作確認メモ

`bundle exec rackup config.ru -p <port>` で起動確認
