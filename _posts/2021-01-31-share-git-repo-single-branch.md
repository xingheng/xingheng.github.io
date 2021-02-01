---
layout: page
title: Share git repo's single branch
description: “"
image:
  path: http://example.jpg
  feature: 
  credit: 
  creditlink: 
tags: [git, shell, command-line]
comments: true
reading_time: true
modified: 2021-01-31

---



> 如何将一个 git repo “正确地”分享给他人？



## 背景

有时候我需要将我写的一些代码仓库分享给别人，同时对方也需要/要求看到我的代码版本历史，这个时候可以用到这些技巧。当然，如果不需要版本历史的话，其实最简单的做法就是 `rm -fr .git && git init && git commit -am “Initial commit.”` 了，然后就可以压缩打包发给别人了。也不全对，因为还需要考虑到本地被 git ignored 的文件。这里我们只讨论通过文件系统下的压缩分享方式，如果是通过 git repo url 的方式的话，那就取决于托管平台的权限控制了，不在讨论范围。



## git ignored

被 git 忽略的文件可能是可以二次下载的三方库文件，也可能是 `.env` 类似的环境变量，甚至可能是自己的密码和私钥文件等等。这个时候我们肯定是需要在分享之前删除这些文件的。

```bash
git check-ignore **/* | xargs rm -fr 
```

还是不够严谨。



## git local branches

如果我有一些特殊本地分支包含了一些密钥文件呢？这种情况还是有的，有时候我会做一些只在本地存在的 branch 来方便 debug，这其中有时候就会有一些比较私密的地方，我不想被别人看到，试试直接删掉。

```bash
git branch -D [private_branch1 private_branch2 ...]
```

还是不够严谨。



## git reflog

想想在 git 中误操作我们以前是怎么操作的？上帝视角（`reflog`）肯定还是能看到的我们具体做了哪些操作的，能删除就能抢救。这种操作不只是我们自己能用，所有的 git 操作记录都会和 git commit 一样存在 `.git`文件夹里面，也可以被别人用到。所以别人也可以恢复我们原本的删除。这就相当于外行在抢救被一不小心发布到 github public repo 里面的服务器密码或者私钥时[提交](https://github.com/search?q=remove+secret&type=commits)了一个新的 `Remove secrets` commit 来解决问题一样。



## git clone local remote

随便找一个 git repo 试试效果，这是原本的摸样：

```bash
➜  hello-service git:(master) git log --oneline
70d20b3 (HEAD -> master) Update the a file.
4e6ed85 Add the c file.
701e06e Add the b file.
f884a5d Initial commit.
➜  hello-service git:(master) git reflog
70d20b3 (HEAD -> master) HEAD@{0}: commit: Update the a file.
4e6ed85 HEAD@{1}: commit: Add the c file.
701e06e HEAD@{2}: commit: Add the b file.
f884a5d HEAD@{3}: commit (initial): Initial commit.
➜  hello-service git:(master)
```

clone 试试：

```shell
➜  git-repos git clone hello-service world-service
Cloning into 'world-service'...
done.
➜  git-repos cd world-service
➜  world-service git:(master) git log --oneline
70d20b3 (HEAD -> master, origin/master, origin/HEAD) Update the a file.
4e6ed85 Add the c file.
701e06e Add the b file.
f884a5d Initial commit.
➜  world-service git:(master) git reflog
70d20b3 (HEAD -> master, origin/master, origin/HEAD) HEAD@{0}: clone: from /Users/me/Desktop/test/git-repos/hello-service
➜  world-service git:(master) git remote -v
origin	/Users/me/Desktop/test/git-repos/hello-service (fetch)
origin	/Users/me/Desktop/test/git-repos/hello-service (push)
➜  world-service git:(master)
```

commits 本身被保留，reflog 干掉了，这就是我想要的！clone 的默认分支是源 repo 的当前分支，如果指定分支的话，`git clone —-branch <branch_name> ` 就行，还有更多可能用得到的 options:

```bash
git clone --branch <branch_name> --single-branch
git clone --branch <branch_name> --no-tags
git clone --branch <branch_name> --no-remote-submodules
```

参照 `git clone —-help` 里面的说明了。

其中 remote `origin` 被保留了，这应该是一件好事，这样就可以通过它来拉取其他可能用得到的分支或者 tag 了。但是我建议在最后分享出去之前还是先把它干掉 `git remote remove origin`，图个干净。

`git clone` 还一并解决了 git ignored files 的问题，根本无需手动删除，这才是最赞的点！



## git reflog, again

`git reflog` 的存储位置是 `.git/log/<ref>` ，相当于存储了所有 commit 的 symbolic link， `git push` 和 `git clone` 的时候并不会把这些 log push/clone 到 remote，所以上面的重建 reflog 的操作才成为可能。实际上 reflog 除了 `show` 操作之外，还有自身的其他 `expire` 和 `delete` 命令，但是好像并不能直接重建所有 log 历史，所以我仍然偏向于用 `git clone` 的方式，它相对更安全和直观，先重建所有，然后选择性改造。



