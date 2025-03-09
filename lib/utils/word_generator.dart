import 'dart:math';

class WordGenerator {
  final List<String> _easyWords = [
    'dog',
    'cat',
    'sun',
    'moon',
    'tree',
    'book',
    'house',
    'car',
    'apple',
    'banana',
    'fish',
    'bird',
    'boat',
    'ball',
    'cake',
    'chair',
    'door',
    'flower',
    'hat',
    'key',
    'lamp',
    'pen',
    'shoe',
    'star',
    'table',
    'watch',
    'window',
    'beach',
    'pizza',
    'robot',
    'smile',
    'snake',
    'train',
    'turtle',
    'umbrella',
    'elephant',
    'glasses',
    'rainbow',
    'rocket',
    'sandwich',
    'snowman',
    'butterfly',
    'hamburger',
    'lollipop',
    'toothbrush',
  ];

  final List<String> _mediumWords = [
    'airplane',
    'basketball',
    'birthday',
    'dinosaur',
    'fireworks',
    'keyboard',
    'mountain',
    'octopus',
    'popcorn',
    'scissors',
    'backpack',
    'bicycle',
    'candle',
    'compass',
    'dolphin',
    'earphones',
    'feather',
    'fountain',
    'hedgehog',
    'jellyfish',
    'ladybug',
    'monster',
    'necklace',
    'pineapple',
    'rainbow',
    'sailboat',
    'strawberry',
    'telescope',
    'unicorn',
    'volcano',
    'waterfall',
    'xylophone',
    'zombie',
    'flamingo',
    'gingerbread',
    'helicopter',
    'ice cream',
    'lighthouse',
    'microscope',
    'observatory',
    'parachute',
    'quarterback',
    'rollercoaster',
    'sunflower',
    'thermometer',
  ];

  final List<String> _hardWords = [
    'astronaut',
    'binoculars',
    'bumblebee',
    'caterpillar',
    'chameleon',
    'cheeseburger',
    'chimpanzee',
    'chocolate',
    'courthouse',
    'dragonfly',
    'escalator',
    'exhausted',
    'firetruck',
    'grasshopper',
    'handshake',
    'headphones',
    'hummingbird',
    'lightbulb',
    'masquerade',
    'mosquito',
    'nightstand',
    'paintbrush',
    'photograph',
    'piñata',
    'porcupine',
    'scarecrow',
    'skyscraper',
    'stethoscope',
    'submarine',
    'sunglasses',
    'surfboard',
    'telephone',
    'television',
    'thumbtack',
    'toothpaste',
    'trampoline',
    'wheelchair',
    'windmill',
    'woodpecker',
    'wristwatch',
    'yogurt',
    'escalator',
    'megaphone',
    'snowboard',
    'ventriloquist',
    'videogame',
  ];

  final Random _random = Random();

  List<String> _allWords() {
    return [..._easyWords, ..._mediumWords, ..._hardWords];
  }

  // Get a specified number of random words
  List<String> getRandomWords(int count, {String? difficulty}) {
    List<String> sourceWords;

    if (difficulty == 'easy') {
      sourceWords = _easyWords;
    } else if (difficulty == 'medium') {
      sourceWords = _mediumWords;
    } else if (difficulty == 'hard') {
      sourceWords = _hardWords;
    } else {
      sourceWords = _allWords();
    }

    if (count >= sourceWords.length) {
      return List<String>.from(sourceWords);
    }

    final shuffled = List<String>.from(sourceWords)..shuffle(_random);
    return shuffled.take(count).toList();
  }

  // Get a single random word
  String getRandomWord({String? difficulty}) {
    return getRandomWords(1, difficulty: difficulty).first;
  }
}
