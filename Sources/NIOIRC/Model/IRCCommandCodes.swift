//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-nio-irc open source project
//
// Copyright (c) 2018 ZeeZide GmbH. and the swift-nio-irc project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIOIRC project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

public enum IRCCommandCode : Int {
  
  // RFC 2812
  
  case replyWelcome            = 1
  case replyYourHost           = 2
  case replyCreated            = 3
  case replyMyInfo             = 4
  case replyBounce             = 5
  
  case replyAway               = 301
  case replyUserhost           = 302
  case replyISON               = 303
  case replyUnAway             = 305
  case replyNowAway            = 306
  
  case replyWhoIsUser          = 311
  case replyWhoIsServer        = 312
  case replyWhoIsOperator      = 313
  case replyWhoWasUser         = 314
  case replyWhoIsIdle          = 317
  case replyEndOfWhoIs         = 318
  case replyWhoIsChannels      = 319
  case replyEndOfWhoWas        = 369
  
  case replyListStart          = 321 // Obsolete
  case replyList               = 322
  case replyListEnd            = 323
  
  case replyChannelModeIs      = 324
  case replyUniqOpIs           = 325
  
  case replyIsLoggedInAs       = 330 // Freenode
  
  case replyNoTopic            = 331
  case replyTopic              = 332
  
  case replyInviting           = 341
  case replySummoning          = 342
  case replyInviteList         = 346
  case replyEndOfInviteList    = 347
  case replyExceptList         = 348
  case replyEndOfExceptList    = 349
  
  case replyVersion            = 351
  case replyWhoReply           = 352
  case replyEndOfWho           = 315
  case replyNameReply          = 353
  case replyEndOfNames         = 366
  
  case replyLinks              = 364
  case replyEndOfLinks         = 365

  case replyBanList            = 367
  case replyEndOfBanList       = 368

  case replyInfo               = 371
  case replyEndOfInfo          = 374
  case replyMotDStart          = 375
  case replyMotD               = 372
  case replyEndOfMotD          = 376
  
  case replyIsConnectingFrom   = 378 // Freenode
  
  case replyYouROper           = 381
  case replyRehashing          = 382
  case replyYourService        = 383
  
  case replyTime               = 391
  case replyUsersStart         = 392
  case replyUsers              = 393
  case replyEndOfUsers         = 394
  case replyNoUsers            = 395
  
  case replyTracelink          = 200
  case replyTraceConnecting    = 201
  case replyTraceHandshake     = 202
  case replyTraceUnknown       = 203
  case replyTraceOperator      = 204
  case replyTraceUser          = 205
  case replyTraceServer        = 206
  case replyTraceService       = 207
  case replyTraceNewType       = 208
  case replyTraceClass         = 209
  case replyTraceReConnect     = 210
  case replyTraceLog           = 261
  case replyTraceEnd           = 262
  
  case replyStatsLinkInfo      = 211
  case replyStatsCommands      = 212
  case replyEndOfStats         = 219
  case replyStatsUptime        = 242
  case replyStatsOLine         = 243
  case replyUModeIs            = 221
  
  case replyServList           = 234
  case replyServListEnd        = 235
  
  case replyLUserClient        = 251
  case replyLUserOp            = 252
  case replyLUserUnknown       = 253
  case replyLUserChannels      = 254
  case replyLUserMe            = 255
  
  case replyAdminMe            = 256
  case replyAdminLoc1          = 257
  case replyAdminLoc2          = 258
  case replyAdminEMail         = 259
  
  case replyTryAgain           = 263
  
  // MARK: - Error Replies (400...599)
  
  case errorNoSuchNick         = 401
  case errorNoSuchServer       = 402
  case errorNoSuchChannel      = 403
  case errorCannotSendToChain  = 404
  case errorTooManyChannels    = 405
  case errorWasNoSuchNick      = 406
  case errorTooManyTargets     = 407
  case errorNoSuchService      = 408
  case errorNoOrigin           = 409
  case errorInvalidCAPCommand  = 410 // IRCv3.net
  case errorNoRecipient        = 411
  case errorNoTextToSend       = 412
  case errorNoTopLevel         = 413
  case errorWildTopLevel       = 414
  case errorBadMask            = 415
  case errorUnknownCommand     = 421
  case errorNoMotD             = 422
  case errorNoAdminInfo        = 423
  case errorFileError          = 424
  case errorNoNickNameGiven    = 431
  case errorErrorneusNickname  = 432
  case errorNicknameInUse      = 433
  case errorNickCollision      = 436
  case errorUnavailResource    = 437
  case errorUserNotInChannel   = 441
  case errorNotOnChannel       = 442
  case errorUserOnChannel      = 443
  case errorNoLogin            = 444
  case errorSummonDisabled     = 445
  case errorUsersDisabled      = 446
  case errorNotRegistered      = 451
  case errorNeedMoreParams     = 461
  case errorAlreadyRegistered  = 462
  case errorNoPermForHost      = 463
  case errorPasswdMismatch     = 464
  case errorYouReBannedCreep   = 465
  case errorYouWillBeBanned    = 466
  case errorKeySet             = 467
  case errorChannelIsFull      = 471
  case errorUnknownMode        = 472
  case errorInviteOnlyChan     = 473
  case errorBannedFromChan     = 474
  case errorBadChannelKey      = 475
  case errorBadChannelMask     = 476
  case errorNoChannelModels    = 477
  case errorBanListFull        = 478
  case errorNoProvileges       = 481
  case errorChanOPrivsNeeded   = 482
  case errorCantKillServer     = 483
  case errorRestricted         = 484
  case errorUniqOpPrivIsNeeded = 485
  case errorNoOperHost         = 491
  
  case errorUModeUnknownFlag   = 501
  case errorUsersDontMatch     = 502
  
  // MARK: - Freenode
  
  case errorIllegalChannelName = 479
}
