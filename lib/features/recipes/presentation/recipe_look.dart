import 'package:flutter/widgets.dart';
import 'package:yaani_eh/core/theme/app_colors.dart';
import 'package:yaani_eh/core/theme/app_icons.dart';
import 'package:yaani_eh/features/catalog_sync/domain/entities/recipe.dart';

/// What a cup layer looks like: its real-life colour.
Color layerColor(RecipeTone tone) => switch (tone) {
  RecipeTone.espresso => AppColors.layerEspresso,
  RecipeTone.coffee || RecipeTone.chai => AppColors.layerCoffee,
  RecipeTone.foam => AppColors.layerFoam,
  RecipeTone.water => AppColors.layerWater,
  RecipeTone.soda => AppColors.layerSoda,
  RecipeTone.milk => AppColors.layerMilk,
  RecipeTone.condensed => AppColors.layerCondensed,
  RecipeTone.chocolate || RecipeTone.hotChocolate => AppColors.layerChocolate,
  RecipeTone.whiteChocolate => AppColors.layerWhiteChocolate,
  RecipeTone.caramel => AppColors.layerCaramel,
  RecipeTone.vanilla || RecipeTone.blendedVanilla => AppColors.layerVanilla,
  RecipeTone.cream || RecipeTone.iceCream => AppColors.layerCream,
  RecipeTone.ice => AppColors.layerIce,
  RecipeTone.blendedCoffee ||
  RecipeTone.blendedCaramel ||
  RecipeTone.other => AppColors.layerMilkCoffee,
  RecipeTone.blendedChocolate || RecipeTone.cookies => AppColors.layerCookies,
  RecipeTone.tea => AppColors.layerTea,
  RecipeTone.greenTea => AppColors.layerGreenTea,
  RecipeTone.matcha => AppColors.layerMatcha,
  RecipeTone.hibiscus => AppColors.layerHibiscus,
  RecipeTone.mintTea => AppColors.layerMint,
  RecipeTone.mango => AppColors.layerMango,
  RecipeTone.strawberry => AppColors.layerStrawberry,
  RecipeTone.orange => AppColors.layerOrange,
  RecipeTone.lemon => AppColors.layerLemon,
  RecipeTone.fruit => AppColors.layerFruit,
  RecipeTone.berry => AppColors.layerBerry,
  RecipeTone.sahlab => AppColors.layerSahlab,
  RecipeTone.nuts => AppColors.layerNuts,
};

/// The picture of a step.
IconData stepIcon(RecipeIcon icon) => switch (icon) {
  RecipeIcon.grind => AppIcons.stepGrind,
  RecipeIcon.shot => AppIcons.coffee,
  RecipeIcon.boil => AppIcons.stepBoil,
  RecipeIcon.steep => AppIcons.stepSteep,
  RecipeIcon.milk => AppIcons.stepMilk,
  RecipeIcon.steam => AppIcons.stepSteam,
  RecipeIcon.pour => AppIcons.stepPour,
  RecipeIcon.ice => AppIcons.stepIce,
  RecipeIcon.blend => AppIcons.stepBlend,
  RecipeIcon.stir => AppIcons.stepStir,
  RecipeIcon.sweeten => AppIcons.stepSweeten,
  RecipeIcon.top => AppIcons.stepTop,
  RecipeIcon.squeeze => AppIcons.stepSqueeze,
  RecipeIcon.serve || RecipeIcon.other => AppIcons.stepServe,
};
